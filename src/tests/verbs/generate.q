// TODO: Generate full set of tests but split into multiple files

dir:first` vs`$ssr[":",string .z.f;"\\";"/"]

castValue:{[x]
  (0 -6 6h!(.z.s';`long$;`long$))[type x;x]}

getValue:{[x]
  ".{ ",(0 -7 -9 7 9h!({".list = &[_]TestValue{ ",(", "sv getValue'[x])," }"};{".int = ",$[null x;"Value.null_int";0W=x;"Value.inf_int";-0W=x;"-Value.inf_int";-3!x]};{".float = ",$[null x;"Value.null_float";0w=x;"Value.inf_float";-0w=x;"-Value.inf_float";ssr[-3!x;"f";""]]};{".int_list = &[_]TestValue{ ",(", "sv getValue'[x])," }"};{".float_list = &[_]TestValue{ ",(", "sv getValue'[x])," }"}))[type x;x:castValue x]," }"}

generate:{[x;y]
  enlist["test \"auto-generated ",x," ",(-3!y),"\" {"],({"    try runTest(\"",x,"\", ",getValue[value x],");"}each x sv'-3!'/:{x cross x}enlist each{x,x cross x}y),enlist enlist"}"}

values:(0N;-0W;0W;0n;-0w;0w)

header:(
  "const value_mod = @import(\"../../value.zig\");";
  "const Value = value_mod.Value;";
  "";
  "const vm_mod = @import(\"../vm.zig\");";
  "const runTest = vm_mod.runTest;";
  "const TestValue = vm_mod.TestValue;";
  "");

{(` sv dir,`$x,".generated.zig")0:header,generate[x;y]}["+";values]