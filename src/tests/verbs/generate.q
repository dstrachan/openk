castValue:{[x]
  dict:0 -6 6h!(.z.s';`long$;`long$);
  dict[type x;x]}

getValueBool:{[x]
  ".boolean = ",$[x;"true";"false"]}

getValueInt:{[x]
  ".int = ",$[null x;"Value.null_int";0W=x;"Value.inf_int";-0W=x;"-Value.inf_int";-3!x]}

getValueFloat:{[x]
  ".float = ",$[null x;"Value.null_float";0w=x;"Value.inf_float";-0w=x;"-Value.inf_float";ssr[-3!x;"f";""]]}

getValueList:{[x]
  ".list = &[_]TestValue{ ",(", "sv getValue'[x])," }"}

getValueBoolList:{[x]
  ".boolean_list = &[_]TestValue{ ",(", "sv getValue'[x])," }"}

getValueIntList:{[x]
  ".int_list = &[_]TestValue{ ",(", "sv getValue'[x])," }"}

getValueFloatList:{[x]
  ".float_list = &[_]TestValue{ ",(", "sv getValue'[x])," }"}

getValue:{[x]
  dict:(!). flip(
    (0h  ;getValueList      );
    (-1h ;getValueBool      );
    (1h  ;getValueBoolList  );
    (-7h ;getValueInt       );
    (7h  ;getValueIntList   );
    (-9h ;getValueFloat     );
    (9h  ;getValueFloatList ));
  ".{ ",dict[type x;x:castValue x]," }"}

generate:{[x;y]
  header:enlist["test \"auto-generated ",x,"\" {"];
  footer:enlist enlist"}";
  c:(1+count y)*count inputs:enlist each{x,x cross x}y;
  header,/:(c cut{"    try runTest(\"",x,"\", ",getValue[value x],");"}each x sv'-3!'/:{x cross x}inputs),\:footer}

dir:first` vs`$ssr[":",string .z.f;"\\";"/"]

values:(0b;1b;0N;-0W;-1;0;1;0W;0n;-0w;-1f;0f;1f;0w)

header:(
  "const value_mod = @import(\"../../../value.zig\");";
  "const Value = value_mod.Value;";
  "";
  "const vm_mod = @import(\"../../vm.zig\");";
  "const runTest = vm_mod.runTest;";
  "const TestValue = vm_mod.TestValue;";
  "")

generateImports:{[x]
  header:enlist["test {"];
  footer:enlist enlist"}";
  header,("    _ = @import(\"",/:string[1+til x],\:".zig\");"),footer}

tests:(
  (`add      ;"+");
  (`subtract ;"-");
  (`multiply ;"*");
  (`divide   ;"%");
  (`concat   ;",");
  (`min      ;"&");
  (`max      ;"|");
  (`less     ;"<");
  (`more     ;">"))

.[{[test;char]
  -1"Generating tests for ",string test;
  if[not()~k:key path:` sv dir,test;
    hdel each(` sv'path,/:k),path];
  generated:header,/:generate[char;asc values];
  imports:generateImports count generated;
  {[path;test;i]
    file:` sv path,` sv(`$string i),`zig;
    file 0:test;
    }[path]'[enlist[imports],generated;(`$"_imports"),1+til count generated];
  };]peach tests;