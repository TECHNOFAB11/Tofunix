{lib, ...}: let
  inherit (lib) removePrefix removeSuffix toList;

  toHCL = val:
    if builtins.isAttrs val
    then
      "{"
      + (builtins.concatStringsSep "," (
        builtins.map (
          key: "${key} = ${toHCL (builtins.getAttr key val)}"
        ) (builtins.attrNames val)
      ))
      + "}}" # somehow needed twice
    else if builtins.isString val
    then "\"${val}\""
    else val;

  removeBraces = input: removePrefix "\${" (removeSuffix "}" input);
  wrapInBraces = input: "\${${input}}";
  inject = func: inputs: let
    inputsNonNull = builtins.filter (el: el != null) (toList inputs);
    inputsStringified = map (el: toString el) inputsNonNull;
    hasBraces = builtins.any (el: lib.hasPrefix "\${" el) inputsStringified;
    params = builtins.map (el: removeBraces el) inputsStringified;
    result = "${func}(${builtins.concatStringsSep ", " params})";
  in
    if hasBraces
    then wrapInBraces result
    else result;
in {
  ab = wrapInBraces;
  rb = removeBraces;
  inherit toHCL;

  # numeric
  abs = input: inject "abs" [input];
  ceil = input: inject "ceil" [input];
  floor = input: inject "floor" [input];
  log = number: base: inject "log" [number base];
  max = values: inject "max" values;
  min = values: inject "min" values;
  parseint = number: base: inject "parseint" [number base];
  pow = first: second: inject "pow" [first second];
  signum = number: inject "signum" [number];

  # string
  chomp = input: inject "chomp" input;
  endswith = string: suffix: inject "endswith" [string suffix];
  format = spec: values: inject "format" [spec] ++ values;
  formatlist = spec: values: inject "formatlist" [spec] ++ values;
  indent = num_spaces: string: inject "indent" [num_spaces string];
  join = separator: list: inject "join" [separator list];
  lower = input: inject "lower" [input];
  regex = pattern: string: inject "regex" [pattern string];
  regexall = pattern: string: inject "regexall" [pattern string];
  replace = string: substring: replacement: inject "replace" [string substring replacement];
  split = separator: string: inject "split" [separator string];
  startswith = string: prefix: inject "startswith" [string prefix];
  strrev = string: inject "strrev" [string];
  substr = string: offset: length: inject "substr" [string offset length];
  title = string: inject "title" [string];
  trim = string: str_character_set: inject "trim" [string str_character_set];
  trimprefix = string: prefix: inject "trimprefix" [string prefix];
  trimsuffix = string: suffix: inject "trimsuffix" [string suffix];
  trimspace = string: inject "trimspace" [string];
  upper = string: inject "upper" [string];

  # collection
  alltrue = list: inject "alltrue" [list];
  anytrue = list: inject "anytrue" [list];
  chunklist = list: chunk_size: inject "chunklist" [list chunk_size];
  coalesce = params: inject "coalesce" params;
  coalescelist = params: inject "coalescelist" params;
  compact = list: inject "compact" [list];
  concat = params: inject "concat" params;
  contains = list: value: inject "contains" [list value];
  distinct = list: inject "distinct" [list];
  element = list: index: inject "element" [list index];
  flatten = list: inject "flatten" [list];
  index = list: value: inject "index" [list value];
  keys = map: inject "keys" (toHCL map); # convert dict to HCL
  length = input: inject "length" [input];
  # list = ) was deprecated
  lookup = map: key: default: inject "lookup" [map key default];
  # map = ) was deprecated
  matchkeys = valueslist: keyslist: searchset: inject "matchkeys" [valueslist keyslist searchset];
  merge = input: inject "merge" input;
  one = list: inject "one" [list];
  range = start: limit: step: inject "range" [start limit step];
  reverse = list: inject "reverse" [list];
  setintersection = sets: inject "setintersection" sets;
  setproduct = sets: inject "setproduct" sets;
  setsubtract = a: b: inject "setsubtract" [a b];
  setunion = sets: inject "setunion" sets;
  slice = list: startindex: endindex: inject "slice" [list startindex endindex];
  sort = list: inject "sort" [list];
  sum = list: inject "sum" [list];
  # TODO: toHCL needs to be called later so we can detect ${}
  #  we need to differentiate between strings, objects and references
  transpose = map: inject "transpose" (toHCL map); # convert dict to HCL
  values = map: inject "values" (toHCL map); # convert dict to HCL
  zipmap = keyslist: valueslist: inject "zipmap" [keyslist valueslist];

  # encoding
  base64decode = string: inject "base64decode" [string];
  base64encode = string: inject "base64encode" [string];
  base64gzip = string: inject "base64gzip" [string];
  csvdecode = string: inject "csvdecode" [string];
  jsondecode = string: inject "jsondecode" [string];
  jsonencode = value: inject "jsonencode" (toHCL value); # convert dict to HCL
  textdecodebase64 = string: encoding_name: inject "textdecodebase64" [string encoding_name];
  textencodebase64 = string: encoding_name: inject "textencodebase64" [string encoding_name];
  urlencode = string: inject "urlencode" [string];
  yamldecode = string: inject "yamldecode" [string];
  yamlencode = value: inject "yamlencode" (toHCL value); # convert dict to HCL

  # filesystem
  abspath = path: inject "abspath" [path];
  dirname = path: inject "dirname" [path];
  pathexpand = path: inject "pathexpand" [path];
  basename = path: inject "basename" [path];
  file = path: inject "file" [path];
  fileexists = path: inject "fileexists" [path];
  fileset = path: pattern: inject "fileset" [path pattern];
  filebase64 = path: inject "filebase64" [path];
  templatefile = path: vars: inject "templatefile" [path vars];

  # date & time
  formatdate = spec: timestamp: inject "formatdate" [spec timestamp];
  timeadd = timestamp: duration: inject "timeadd" [timestamp duration];
  timecmp = timestamp_a: timestamp_b: inject "timecmp" [timestamp_a timestamp_b];
  timestamp = inject "timestamp" [];

  # hash & crypto
  base64sha256 = string: inject "base64sha256" [string];
  base64sha512 = string: inject "base64sha512" [string];
  bcrypt = string: cost: inject "bcrypt" [string cost];
  filebase64sha256 = file: inject "filebase64sha256" [file];
  filebase64sha512 = file: inject "filebase64sha512" [file];
  filemd5 = file: inject "filemd5" [file];
  filesha1 = file: inject "filesha1" [file];
  filesha256 = file: inject "filesha256" [file];
  filesha512 = file: inject "filesha512" [file];
  md5 = string: inject "md5" [string];
  rsadecrypt = ciphertext: privatekey: inject "rsadecrypt" [ciphertext privatekey];
  sha1 = string: inject "sha1" [string];
  sha256 = string: inject "sha256" [string];
  sha512 = string: inject "sha512" [string];
  uuid = inject "uuid" [];
  uuidv5 = namespace: name: inject "uuidv5" [namespace name];

  # ip network
  cidrhost = prefix: hostnum: inject "cidrhost" [prefix hostnum];
  cidrnetmask = prefix: inject "cidrnetmask" [prefix];
  cidrsubnet = prefix: newbits: netnum: inject "cidrsubnet" [prefix newbits netnum];
  cidrsubnets = prefix: newbits: inject "cidrsubnets" [prefix] ++ newbits;

  # type conversion
  can = expression: inject "can" [expression];
  nonsensitive = value: inject "nonsensitive" [value];
  sensitive = value: inject "sensitive" [value];
  tobool = value: inject "tobool" [value];
  tolist = value: inject "tolist" [value];
  tomap = value: inject "tomap" [value];
  tonumber = value: inject "tonumber" [value];
  toset = value: inject "toset" [value];
  tostring = value: inject "tostring" [value];
  try = expressions: inject "try" expressions;
  type = value: inject "type" [value];
}
