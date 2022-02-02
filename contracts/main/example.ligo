#include "../partial/example_types.ligo"
#include "../partial/example_methods.ligo"

function main(
  const action          : parameter_t;
  const s               : storage_t)
                        : return_t is
  case action of
  | Example(params)           -> (no_operations, do(params, s))
  | Example_2(params)         -> (no_operations, do(params, s))
  end
