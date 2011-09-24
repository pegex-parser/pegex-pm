package Pegex::Parser::Indent;

# The indentation levels of consecutive lines are used to generate INDENT and
# DEDENT tokens, using a stack, as follows. Before the first line of the file
# is read, a single zero is pushed on the stack; this will never be popped off
# again. The numbers pushed on the stack will always be strictly increasing
# from bottom to top. At the beginning of each logical line, the line’s
# indentation level is compared to the top of the stack. If it is equal,
# nothing happens. If it is larger, it is pushed on the stack, and one INDENT
# token is generated. If it is smaller, it must be one of the numbers
# occurring on the stack; all numbers on the stack that are larger are popped
# off, and for each number popped off a DEDENT token is generated. At the end
# of the file, a DEDENT token is generated for each number remaining on the
# stack that is larger than zero. ''

1;
