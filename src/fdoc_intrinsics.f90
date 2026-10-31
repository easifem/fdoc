module fdoc_intrinsics
!! Names that are not procedures of the project: Fortran's keywords and intrinsic procedures, with
!! common compiler extensions.
implicit none
private

public :: is_intrinsic

integer, parameter :: NAME_LEN = 30
character(len=NAME_LEN), parameter :: NAMES(422) = [character(len=NAME_LEN) :: &
    'abort', 'abs', 'abstract', 'access', 'achar', 'acos', 'acosh', 'adjustl', 'adjustr', 'aimag', 'aint', &
    'alarm', 'all', 'allocatable', 'allocate', 'allocated', 'and', 'anint', 'any', 'asin', 'asinh', &
    'assign', 'associate', 'associated', 'asynchronous', 'atan', 'atan2', 'atanh', 'atomic_add', &
    'atomic_and', 'atomic_cas', 'atomic_define', 'atomic_fetch_add', 'atomic_fetch_and', 'atomic_fetch_or', &
    'atomic_fetch_xor', 'atomic_or', 'atomic_ref', 'atomic_xor', 'backspace', 'backtrace', 'bessel_j0', &
    'bessel_j1', 'bessel_jn', 'bessel_y0', 'bessel_y1', 'bessel_yn', 'bge', 'bgt', 'bind', 'bit_size', &
    'ble', 'block', 'blt', 'btest', 'c_associated', 'c_f_pointer', 'c_f_procpointer', 'c_funloc', 'c_loc', &
    'c_sizeof', 'cabs', 'call', 'case', 'cdabs', 'ceiling', 'char', 'character', 'chdir', 'chmod', 'class', &
    'close', 'cmplx', 'co_broadcast', 'co_max', 'co_min', 'co_reduce', 'co_sum', 'codimension', &
    'command_argument_count', 'common', 'compiler_options', 'compiler_version', 'complex', 'concurrent', &
    'conjg', 'contains', 'contiguous', 'continue', 'cos', 'cosh', 'count', 'cpu_time', 'critical', &
    'cshift', 'ctime', 'cycle', 'dabs', 'data', 'date_and_time', 'dble', 'dcmplx', 'deallocate', &
    'deferred', 'digits', 'dim', 'dimension', 'dlog', 'dlog10', 'dmax1', 'dmin1', 'do', 'dot_product', &
    'dprod', 'dreal', 'dshiftl', 'dshiftr', 'dsqrt', 'dtime', 'elemental', 'else', 'elseif', 'elsewhere', &
    'end', 'endfile', 'endif', 'entry', 'enum', 'enumerator', 'eoshift', 'epsilon', 'equivalence', 'erf', &
    'erfc', 'erfc_scaled', 'etime', 'execute_command_line', 'exit', 'exp', 'exponent', 'extends', &
    'extends_type_of', 'external', 'fdate', 'fget', 'fgetc', 'final', 'findloc', 'floor', 'flush', 'fnum', &
    'forall', 'format', 'fput', 'fputc', 'fraction', 'free', 'fseek', 'fstat', 'ftell', 'function', &
    'gamma', 'generic', 'gerror', 'get_command', 'get_command_argument', 'get_environment_variable', &
    'getarg', 'getcwd', 'getenv', 'getgid', 'getlog', 'getpid', 'getuid', 'gmtime', 'goto', 'hostnm', &
    'huge', 'hypot', 'iabs', 'iachar', 'iall', 'iand', 'iany', 'iargc', 'ibclr', 'ibits', 'ibset', 'ichar', &
    'idate', 'ieee_class', 'ieee_copy_sign', 'ieee_get_flag', 'ieee_get_halting_mode', &
    'ieee_get_rounding_mode', 'ieee_get_status', 'ieee_get_underflow_mode', 'ieee_is_finite', &
    'ieee_is_nan', 'ieee_is_negative', 'ieee_is_normal', 'ieee_logb', 'ieee_next_after', 'ieee_rem', &
    'ieee_rint', 'ieee_scalb', 'ieee_selected_real_kind', 'ieee_set_flag', 'ieee_set_halting_mode', &
    'ieee_set_rounding_mode', 'ieee_set_status', 'ieee_support_datatype', 'ieee_support_denormal', &
    'ieee_support_divide', 'ieee_support_flag', 'ieee_support_halting', 'ieee_support_inf', &
    'ieee_support_io', 'ieee_support_nan', 'ieee_support_rounding', 'ieee_support_sqrt', &
    'ieee_support_standard', 'ieee_support_underflow_control', 'ieee_unordered', 'ieee_value', 'ieor', &
    'ierrno', 'if', 'imag', 'image_index', 'implicit', 'import', 'include', 'index', 'inquire', 'int', &
    'int2', 'int8', 'integer', 'intent', 'interface', 'intrinsic', 'ior', 'iparity', 'irand', 'is', &
    'is_contiguous', 'is_iostat_end', 'is_iostat_eor', 'isatty', 'ishft', 'ishftc', 'isnan', 'itime', &
    'kill', 'kind', 'lbound', 'lcobound', 'leadz', 'len', 'len_trim', 'lge', 'lgt', 'link', 'lle', 'llt', &
    'lnblnk', 'loc', 'lock', 'log', 'log10', 'log_gamma', 'logical', 'long', 'lshift', 'lstat', 'ltime', &
    'malloc', 'maskl', 'maskr', 'matmul', 'max', 'max0', 'maxexponent', 'maxloc', 'maxval', 'mclock', &
    'mclock8', 'merge', 'merge_bits', 'min', 'min0', 'minexponent', 'minloc', 'minval', 'mod', 'module', &
    'modulo', 'move_alloc', 'mvbits', 'namelist', 'nearest', 'new_line', 'nint', 'non_overridable', 'none', &
    'nopass', 'norm2', 'not', 'null', 'nullify', 'num_images', 'only', 'open', 'operator', 'optional', &
    'or', 'pack', 'parameter', 'parity', 'pass', 'pause', 'perror', 'pointer', 'popcnt', 'poppar', &
    'precision', 'present', 'print', 'private', 'procedure', 'product', 'program', 'protected', 'public', &
    'pure', 'radix', 'ran', 'rand', 'random_number', 'random_seed', 'range', 'rank', 'read', 'real', &
    'recursive', 'rename', 'repeat', 'reshape', 'result', 'return', 'rewind', 'rewrite', 'rrspacing', &
    'rshift', 'same_type_as', 'save', 'scale', 'scan', 'secnds', 'second', 'select', 'selected_char_kind', &
    'selected_int_kind', 'selected_real_kind', 'sequence', 'set_exponent', 'shape', 'shifta', 'shiftl', &
    'shiftr', 'sign', 'signal', 'sin', 'sinh', 'size', 'sizeof', 'sleep', 'spacing', 'spread', 'sqrt', &
    'srand', 'stat', 'stop', 'storage_size', 'submodule', 'subroutine', 'sum', 'symlnk', 'system', &
    'system_clock', 'tan', 'tanh', 'target', 'then', 'this_image', 'time', 'time8', 'tiny', 'trailz', &
    'transfer', 'transpose', 'trim', 'ttynam', 'type', 'type_as', 'ubound', 'ucobound', 'umask', 'unlink', &
    'unlock', 'unpack', 'use', 'value', 'verify', 'volatile', 'wait', 'where', 'while', 'write', 'xor', &
    'zabs']

contains

!> True if `name`, in lowercase, is one of the names.
pure logical function is_intrinsic(name)
    character(len=*), intent(in) :: name    !! the name
    integer :: low, high, middle

    is_intrinsic = .false.
    if (len(name) > NAME_LEN) return
    low = 1
    high = size(NAMES)
    do while (low <= high)
        middle = (low + high)/2
        if (name == NAMES(middle)) then
            is_intrinsic = .true.
            return
        else if (lgt(name, NAMES(middle))) then
            low = middle + 1
        else
            high = middle - 1
        end if
    end do
end function is_intrinsic

end module fdoc_intrinsics
