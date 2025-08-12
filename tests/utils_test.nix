{tflib, ...}: {
  suites."Utils" = {
    pos = __curPos;
    tests = let
      inherit (tflib) utils;
      ref = utils.ab "local.some_value";
    in [
      {
        name = "string utils: upper";
        expected = "upper(HELLO)";
        actual = utils.upper "HELLO";
      }
      {
        name = "string utils: upper with reference";
        expected = "\${upper(local.some_value)}";
        actual = utils.upper ref;
      }
      {
        name = "collection utils: join";
        expected = "join(\", \", [a, b])";
        actual = utils.join "\", \"" ["a" "b"];
      }
      {
        name = "collection utils: merge with references";
        expected = "\${merge(local.a, local.b)}";
        actual = utils.merge [(utils.ab "local.a") (utils.ab "local.b")];
      }
      {
        name = "numeric utils: min with reference";
        expected = "\${min(1, 2, local.some_value)}";
        actual = utils.min [1 2 ref];
      }
      {
        name = "type conversion utils: tostring";
        expected = "tostring(123)";
        actual = utils.tostring 123;
      }
    ];
  };
}
