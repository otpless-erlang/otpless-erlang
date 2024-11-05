#!/usr/bin/env perl -W
#
# %CopyrightBegin%
#
# Copyright Ericsson AB 2022-2024. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# %CopyrightEnd%
#
use strict;

# Please keep the names in the list in alphabetical order.
my @beam_global_funcs = qw(
    apply_fun_shared
    arith_compare_shared
    bif_nif_epilogue
    bif_export_trap
    bif_bit_size_body
    bif_byte_size_body
    bif_element_body_shared
    bif_element_guard_shared
    bif_is_eq_exact_shared
    bif_is_ne_exact_shared
    bif_tuple_size_body
    bif_tuple_size_guard
    bs_add_guard_shared
    bs_add_body_shared
    bs_create_bin_error_shared
    bs_get_tail_shared
    bs_get_utf8_shared
    bs_get_utf8_short_shared
    bs_init_bits_shared
    bs_size_check_shared
    call_bif_shared
    call_light_bif_shared
    call_nif_yield_helper
    catch_end_shared
    call_nif_early
    call_nif_shared
    check_float_error
    construct_utf8_shared
    debug_bp
    dispatch_bif
    dispatch_nif
    dispatch_return
    dispatch_save_calls_export
    dispatch_save_calls_fun
    export_trampoline
    fconv_shared
    get_sint64_shared
    handle_and_error
    handle_call_fun_error
    handle_element_error_shared
    handle_hd_error
    handle_map_get_badkey
    handle_map_get_badmap
    handle_map_size_error
    handle_node_error
    handle_not_error
    handle_or_error
    handle_tl_error
    garbage_collect
    generic_bp_global
    generic_bp_local
    i_band_body_shared
    i_bnot_body_shared
    i_bnot_guard_shared
    i_bor_body_shared
    i_bif_body_shared
    i_bif_guard_shared
    i_breakpoint_trampoline_shared
    i_bsr_body_shared
    i_bsl_body_shared
    i_func_info_shared
    i_get_map_element_shared
    i_get_map_element_hash_shared
    i_length_guard_shared
    i_length_body_shared
    i_loop_rec_shared
    i_test_yield_shared
    i_bxor_body_shared
    int128_to_big_shared
    int_div_rem_body_shared
    int_div_rem_guard_shared
    is_eq_exact_list_shared
    is_eq_exact_shallow_boxed_shared
    is_in_range_shared
    is_ge_lt_shared
    minus_body_shared
    mul_add_body_shared
    mul_add_guard_shared
    mul_body_shared
    mul_guard_shared
    new_map_shared
    plus_body_shared
    process_exit
    process_main
    raise_exception
    raise_exception_null_exp
    raise_exception_shared
    raise_shared
    store_unaligned
    unloaded_fun
    unary_minus_body_shared
    update_map_assoc_shared
    update_map_single_assoc_shared
    update_map_exact_guard_shared
    update_map_exact_body_shared
    update_map_single_exact_body_shared
    );


# Labels exported from within process_main
my @process_main_labels = qw(
    context_switch
    context_switch_simplified
    do_schedule
    );

my $decl_enums =
    gen_list('        %s,', @beam_global_funcs, '', @process_main_labels);

my $decl_emit_funcs =
    gen_list('    void emit_%s(void);', @beam_global_funcs);

my $decl_get_funcs =
    gen_list('    void (*get_%s(void))() { return get(%s); }',
             @beam_global_funcs, '', @process_main_labels);

my $decl_emitPtrs =
    gen_list('    {%s, &BeamGlobalAssembler::emit_%s},', @beam_global_funcs);

my $decl_label_names =
    gen_list('    {%s, "%s"},', @beam_global_funcs, '', @process_main_labels);

sub gen_list {
    my ($format, @strings) = @_;
    my $out = '';
    foreach my $str (@strings) {
        if ($str eq '') {
            $out .= "\n";
        }
        else {
            my $subst = $format;
            $subst =~ s/%s/$str/g;
            $out .= "$subst\n";
        }
    }
    $out;
}


my $this_source_file = __FILE__;

print <<END_OF_FILE;
/*
 *  Warning: Do not edit this file.
 *  Auto-generated by $this_source_file.
 */

#ifndef _BEAM_ASM_GLOBAL_HPP
#define _BEAM_ASM_GLOBAL_HPP


class BeamGlobalAssembler : public BeamAssembler {
    typedef void (BeamGlobalAssembler::*emitFptr)(void);
    typedef void (*fptr)(void);

    enum GlobalLabels : uint32_t {
$decl_enums
    };

    static const std::map<GlobalLabels, const std::string> labelNames;
    static const std::map<GlobalLabels, emitFptr> emitPtrs;
    std::unordered_map<GlobalLabels, Label> labels;
    std::unordered_map<GlobalLabels, fptr> ptrs;

$decl_emit_funcs

    template<typename T>
    void emit_bitwise_fallback_body(T(*func_ptr), const ErtsCodeMFA *mfa);

    void emit_i_length_common(Label fail, int state_size);

    void emit_raise_badarg(const ErtsCodeMFA *mfa);

    void emit_bif_bit_size_helper(Label fail);
    void emit_bif_element_helper(Label fail);
    void emit_bif_tuple_size_helper(Label fail);

    void emit_internal_hash_helper();
    void emit_flatmap_get_element();
    void emit_hashmap_get_element();

public:
    BeamGlobalAssembler(JitAllocator *allocator);

    void (*get(GlobalLabels lbl))(void) {
        ASSERT(ptrs[lbl]);
        return ptrs[lbl];
    }

$decl_get_funcs
};

#ifdef ERTS_BEAM_ASM_GLOBAL_WANT_STATIC_DEFS

const std::map<BeamGlobalAssembler::GlobalLabels, BeamGlobalAssembler::emitFptr>
BeamGlobalAssembler::emitPtrs = {
$decl_emitPtrs
};

const std::map<BeamGlobalAssembler::GlobalLabels, const std::string>
BeamGlobalAssembler::labelNames = {
$decl_label_names
};

#endif /* ERTS_BEAM_ASM_GLOBAL_WANT_STATIC_DEFS */

#endif /* !_BEAM_ASM_GLOBAL_HPP */
END_OF_FILE
