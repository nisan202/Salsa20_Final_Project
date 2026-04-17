#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use File::Path qw(make_path);
use Tie::IxHash;

#######################################################
# to RUN: perl Text_Vector_to_Json.pl <input file txt> 
#######################################################

# ========== CONFIG ==========
my $input_file  = shift || 'vectors_input.txt';
my $output_dir  = 'output_json';
my $output_file = "$output_dir/vectors_final.json";

unless (-d $output_dir) {
    make_path($output_dir) or die "❌ Cannot create directory $output_dir: $!";
}

# Address ranges (DW addresses)
my %address_ranges = (
	PLAIN_TEXT	=> 0x02,	
    KEY     	=> 0x12,
	NONCE   	=> 0x1A,
    COUNTER 	=> 0x1C,
    HASHING 	=> 0x1E,
    CIPHER  	=> 0x2E,
);

# Each register occupies one address (32-bit DW)
my $addr_step = 1;

#==========================================
#=========== auxiliary functions ==========
#==========================================

#--------------------------------------
#---------- normalize_hex() -----------
#"cleans" a Hex string — Only normal characters, no noise, in lowercase

sub normalize_hex {
    my ($s) = @_;
    return '' unless defined $s;
    $s =~ s/[^0-9a-fA-F]//g;
    return lc $s;
}

#--------------------------------------
#---------- list_to_flat_hex ----------
# from list to bus

sub list_to_flat_hex {
    my ($list_str) = @_;
    return '' unless defined $list_str;
	
    my @items = $list_str =~ /'([^']+)'|"([^"]+)"|([0-9A-Fa-f]+)/g;
	
    my @clean;
    foreach my $t (@items) {
        next unless defined $t and $t ne '';
        my $h = $t;
        $h =~ s/[^0-9a-fA-F]//g;
        push @clean, $h if $h ne '';
    }
    return lc join('', @clean);
}

#-------------------------------------
#---------- hex_to_chunks32 ----------
# bus to chunck

sub hex_to_chunks32 {
    my ($hex) = @_;
    $hex = normalize_hex($hex || '');
    return () unless $hex ne '';
	
    my $rem = length($hex) % 8;
    if ($rem != 0) {
        my $pad = 8 - $rem;
        $hex = ('0' x $pad) . $hex;
    }
    my @chunks = ($hex =~ /(.{8})/g);
    return @chunks;
}

#--------------------------------------
#---------- value_to_swap -------------
# Converts 32-bit hex value (e.g., "0x529E5030") to dw in little-endian order

sub value_to_swap {
    my ($hex_val) = @_;
    $hex_val =~ s/^0x//i; #remove 0x                # הסר 0x
    $hex_val = lc($hex_val); #lower case
    $hex_val = sprintf("%08s", $hex_val); #verify 8 digits

    # split to 4 Byte
    my @bytes = ($hex_val =~ /(..)(..)(..)(..)/);

    # little endian
    my $swap_val = join('', reverse @bytes);

    # return with 0x
    return "0x" . uc($swap_val);
}

#------------------------------------
#---------- make_regs_flex ----------
# 
sub make_regs_flex {
    my (%args) = @_;

    my $hex        = $args{hex};
    my $values     = $args{values};
    my $base_addr  = $args{base_addr} // 0;
    my $step       = $args{step} // 1;
    my $reverse    = $args{reverse} // 0;
    my $as_expected= $args{as_expected} // 0;

    # Builds the list of values
    my @vals;
    if (defined $values) {
        @vals = @$values;
    } elsif (defined $hex) {
        @vals = hex_to_chunks32($hex);
    } else {
        return [];  # no input
    }

    # reverse
    @vals = reverse @vals if $reverse;

    # make regs
    my @regs;
    for my $i (0 .. $#vals) {
        my $addr = sprintf("0x%02X", $base_addr + $i * $step);
        my $val  = sprintf("0x%s", uc($vals[$i]));
		tie my %reg, 'Tie::IxHash';
        if ($as_expected) {
            %reg = (address => $addr, expected_value => $val );
        } else {
			my $swap_ref = value_to_swap($val); 
            %reg = (
				address => $addr,
				value => $val,
				swap_bytes => $swap_ref,
			);
        }
		push @regs, \%reg;
    }

    return \@regs;
}

#-------------------------------------------
#---------- extract_matrix_values ----------
#
sub extract_matrix_values {
    my ($matrix_text) = @_;
    my @values;

    while ($matrix_text =~ /'([0-9a-fA-F]+)'/g) {
        push @values, $1;
    }
	
    return @values;
}

# ====================================================
# =============== Reading the file ===================
# ====================================================

open(my $fh, '<', $input_file) or die "Cannot open $input_file: $!";

my @tests;                    # array of hashrefs
my $current = '';             # keep all the text of the current block
my $current_num;              # current test number

while (my $line = <$fh>) {
    # Detecting the start of a new test
    if ($line =~ /^Test\s+Number\s+(\d+)/i) {
        # If there is a current block, we will process it.
        if (defined $current && $current ne '') {
            my $test_obj = process_block($current, $current_num);
            push @tests, $test_obj if $test_obj;
        }
        # Start a new block
        $current_num = $1;
        $current = $line;
    } else {
        $current .= $line;
    }
}
# Process the last block
if (defined $current && $current ne '') {
    my $test_obj = process_block($current, $current_num);
    push @tests, $test_obj if $test_obj;
}
close($fh);

# ====================================================
# ============ JSON generation and writing ===========
# ====================================================

my $json = JSON->new->utf8->pretty;
#my $json = JSON->new->utf8->canonical;
open(my $out, '>:encoding(UTF-8)', $output_file) or die "Cannot write $output_file: $!";
print $out $json->encode(\@tests);
close($out);
print "Process Done! Wrote " . scalar(@tests) . " tests to $output_file\n";


# ====================================================
# ========== processes a single text block ===========
# ====================================================

sub process_block {
    my ($block_text, $num) = @_;
    return undef unless defined $block_text;
	
	#----- plain text -----
	my @plain_hex;
	#if ($block_text =~ /Plain_Matrix_Hex\s*=\s*((?:\s*\[[^\]]*\]\s*)+)/s) {
	if ($block_text =~ /Plain_Matrix_Hex\s*=\s*((?:\[[^\]]*\]\s*)+)/s) {
		my $plain_matrix_text = $1;
		
		#@plain_hex = extract_matrix_values($plain_matrix_text);
		while ($plain_matrix_text =~ /'([0-9a-fA-F]+)'/g) {
			push @plain_hex, $1;
		}
	}
	
	# ----- key -----
	my @key_hex;
	if ($block_text =~ /Key_Hex_List\s*=\s*(\[[^\]]+\])/s) {
		my $key_list_text = $1;
		
		while ($key_list_text =~ /'([0-9a-fA-F]+)'/g) {
			push @key_hex, $1;
		}
	}

    # ----- Nonce -----
	my @nonce_hex;
	if ($block_text =~ /Nonce_Hex_List\s*=\s*(\[[^\]]+\])/s) {
		my $nonce_list_text = $1;
		
		while ($nonce_list_text =~ /'([0-9a-fA-F]+)'/g) {
			push @nonce_hex, $1;
		}
	}
	
	# ----- Counter -----
	my @counter_hex;
	if ($block_text =~ /Counter_Hex_List\s*=\s*(\[[^\]]+\])/s) {
		my $counter_list_text = $1;
		
		while ($counter_list_text =~ /'([0-9a-fA-F]+)'/g) {
			push @counter_hex, $1;
		}
	}
	
	# ----- Hashing -----
	my @hash_hex;
	if ($block_text =~ /Hashing_Matrix_Hex\s*=\s*((?:\[[^\]]*\]\s*)+)/s) {
		my $hash_matrix_text = $1;
		
		while ($hash_matrix_text =~ /'([0-9a-fA-F]+)'/g) {
        push @hash_hex, $1;
		}
	}
	
	# ----- Cipher -----
	my @cipher_hex;
	if ($block_text =~ /Cipher_Matrix_Hex\s*=\s*((?:\[[^\]]*\]\s*)+)/s) {
		my $cipher_matrix_text = $1;
		
		while ($cipher_matrix_text =~ /'([0-9a-fA-F]+)'/g) {
        push @cipher_hex, $1;
		}
	}
	
	# ----- Decryption ----- 
	my @decryption_hex;
	if ($block_text =~ /Decryption_Matrix_Hex\s*=\s*((?:\[[^\]]*\]\s*)+)/s) {
		my $decryption_matrix_text = $1;
		
		while ($decryption_matrix_text =~ /'([0-9a-fA-F]+)'/g) {
        push @decryption_hex, $1;
		}
	}
	
	# ----- Test Number -----
	my $test_id = '';
	my $description = '';
	
	if ($block_text =~ /Test\s+Number\s+(\d+)/i) {
		$test_id = $1;
		$description = "Test Number $test_id";
	}

    # ----- if empty ----- 
	@plain_hex	 	= () unless  @plain_hex;
    @key_hex     	= () unless  @key_hex;
    @nonce_hex   	= () unless  @nonce_hex;
    @counter_hex	= () unless  @counter_hex;
	@hash_hex	 	= () unless  @hash_hex;
	@cipher_hex  	= () unless  @cipher_hex;
	@decryption_hex	= () unless  @decryption_hex;
	
	# ----- make regs (with reverse=1)----- 
	my $encrypt_plain_regs = make_regs_flex (
						values => \@plain_hex,
						base_addr => $address_ranges{PLAIN_TEXT},
						step => $addr_step,
						reverse => 1,
						as_expected => 0
					);
	##### in decrypt mode we replace between plain and cipher				
	my $decrypr_plain_regs = make_regs_flex (
						values => \@cipher_hex,
						base_addr => $address_ranges{PLAIN_TEXT},
						step => $addr_step,
						reverse => 1,
						as_expected => 0
					);
	
    my $key_regs  = make_regs_flex (
						values => \@key_hex,
						base_addr => $address_ranges{KEY},
						step => $addr_step,
						reverse => 1,
						as_expected => 0
					);
					
    my $nonce_regs = make_regs_flex (
						values => \@nonce_hex,
						base_addr => $address_ranges{NONCE},
						step => $addr_step,
						reverse => 1,
						as_expected => 0
					);
	
	my $counter_regs = make_regs_flex (
						values => \@counter_hex,
						base_addr => $address_ranges{COUNTER},
						step => $addr_step,
						reverse => 1,
						as_expected => 0
					);
	
	my $hash_regs = make_regs_flex (
						values => \@hash_hex,
						base_addr => $address_ranges{HASHING},
						step => $addr_step,
						reverse => 1,
						as_expected => 0
					);

	my $cipher_regs = make_regs_flex (
						values => \@cipher_hex,
						base_addr => $address_ranges{CIPHER},
						step => $addr_step,
						reverse => 1,
						as_expected => 0
					);
	
	my @decryption_reversed = reverse @decryption_hex;

#-----------------------------------------------------
#=========================================================
	tie my %plain_ordered, 'Tie::IxHash';
	%plain_ordered = (
		encrypt_mode  => $encrypt_plain_regs,
		decrypt_mode  => $decrypr_plain_regs,
	);

	tie my %registers_ordered, 'Tie::IxHash';
	%registers_ordered = (
		PLAIN_TEXT => \%plain_ordered,
		KEY        => $key_regs,
		NONCE      => $nonce_regs,
		COUNTER    => $counter_regs,
		HASHING    => $hash_regs,
		CIPHER     => $cipher_regs,
	);
	
	tie my %decryption_ordered, 'Tie::IxHash';
	%decryption_ordered = (
		normal   => \@decryption_hex,
		reversed => \@decryption_reversed,
	);
	
	tie my %vectors_ordered, 'Tie::IxHash';
	%vectors_ordered = (
		PLAIN      => \@plain_hex,
		KEY        => \@key_hex,
		NONCE      => \@nonce_hex,
		COUNTER    => \@counter_hex,
		HASH       => \@hash_hex,
		CIPHER     => \@cipher_hex,
		DECRYPTION => \%decryption_ordered
	);

	tie my %test_ordered, 'Tie::IxHash';
	%test_ordered = (
		Test_ID     => $test_id,
		Description => $description,
		VECTORS     => \%vectors_ordered,
		REGISTERS   => \%registers_ordered
	);

	return \%test_ordered;
}