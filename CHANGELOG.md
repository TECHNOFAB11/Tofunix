# Changelog
All notable changes to this project will be documented in this file. See [conventional commits](https://www.conventionalcommits.org/) for commit guidelines.

- - -
## [v2.1.0](https://gitlab.com/TECHNOFAB/tofunix/compare/v2.0.0..v2.1.0) - 2025-12-31
#### Features
- switch from flake-parts and devenv to rensa ecosystem - ([e322713](https://gitlab.com/TECHNOFAB/tofunix/commit/e3227131c2013389a4e862130ea71a74097444f7)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Bug Fixes
- (**generator**) handle nested_type, fixes providers like cloudflare - ([bff132d](https://gitlab.com/TECHNOFAB/tofunix/commit/bff132d1118997e1f517abbcd893a5ab65ae3f20)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Documentation
- add comparison to terranix & examples - ([aa8e76f](https://gitlab.com/TECHNOFAB/tofunix/commit/aa8e76ffd1efcc013fe23fe76a2fc36cba05f953)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Miscellaneous Chores
- (**cli**) pass through module for easy access - ([cb0605c](https://gitlab.com/TECHNOFAB/tofunix/commit/cb0605cf53f61286407345d1ee32395e54ba42d1)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- add a bunch of addErrorContext to help debugging & add docs - ([39001dd](https://gitlab.com/TECHNOFAB/tofunix/commit/39001ddac8969c210ae41190005128c35777d274)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)

- - -

## [v2.0.0](https://gitlab.com/TECHNOFAB/tofunix/compare/v1.0.0..v2.0.0) - 2025-11-13
#### Features
- (**module**) improve references to allow for arbitrary accessors - ([4091db6](https://gitlab.com/TECHNOFAB/tofunix/commit/4091db62baacb1a6ecb874ea1df104aed1740aeb)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- improve generator and module a lot, handle edge cases etc. - ([c194703](https://gitlab.com/TECHNOFAB/tofunix/commit/c194703c886b4515662871612905deccf0c1065a)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Bug Fixes
- (**ci**) add test stage - ([2969f69](https://gitlab.com/TECHNOFAB/tofunix/commit/2969f6978da1a18f62823f198b7f5313210d7890)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- (**generator**) add reference type to nested types - ([05ef67e](https://gitlab.com/TECHNOFAB/tofunix/commit/05ef67e1120437228925317c06a8ff4b6ee93a8a)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- remove registry when the user initially didn't specify any - ([69bffa5](https://gitlab.com/TECHNOFAB/tofunix/commit/69bffa53c525d6128b6a23743149e37c72d3d5ba)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- minor issue - ([c80ce84](https://gitlab.com/TECHNOFAB/tofunix/commit/c80ce846e1d2ba6ac249583b38de399cd83eb05c)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Documentation
- add example for generated provider option docs - ([f807897](https://gitlab.com/TECHNOFAB/tofunix/commit/f807897b262d8db631235e5dbbd7a1eb6528af44)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- update nixmkdocs, set site_url, add style.css & switch to svg logo - ([36ee214](https://gitlab.com/TECHNOFAB/tofunix/commit/36ee214ba4195c2316296bc7eb12d6758eed9fdc)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Tests
- add tests for module and packaging - ([68c5ad4](https://gitlab.com/TECHNOFAB/tofunix/commit/68c5ad4ff9b2603d902c65f5654e48868c0e1ff6)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Miscellaneous Chores
- (**lib**) pass utils to module - ([271ad15](https://gitlab.com/TECHNOFAB/tofunix/commit/271ad1597c938dab8354368d836bc2d19401660c)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- (**utils**) add quot function - ([c82a520](https://gitlab.com/TECHNOFAB/tofunix/commit/c82a5202575bce84cfea6af92415054f9892058f)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- rewrite module to use unset type instead of nulls - ([c2e356b](https://gitlab.com/TECHNOFAB/tofunix/commit/c2e356bd0fe6e886f02d2764cb7bcc66e81dfaa3)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- update nixtest and add grep to tests - ([68fd1ba](https://gitlab.com/TECHNOFAB/tofunix/commit/68fd1bac7b0f528da74e2616b172d52906834f56)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- add initial tests and minor improvements - ([ccf7305](https://gitlab.com/TECHNOFAB/tofunix/commit/ccf73059822062c0b4d7423dfbd89a0e17a96e62)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)

- - -

## [v1.0.0](https://gitlab.com/TECHNOFAB/tofunix/compare/7a355b7cf4001515249157548dd4f608d44a9252..v1.0.0) - 2025-08-09
#### Features
- add gitlab tofu support - ([a3c5142](https://gitlab.com/TECHNOFAB/tofunix/commit/a3c5142d7edf8aa03a912252fe27ea0b242b0f8a)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Bug Fixes
- (**flake**) use nix-gitlab-ci v2 - ([b74fe7c](https://gitlab.com/TECHNOFAB/tofunix/commit/b74fe7cc49a1d78e28638d305f411a933658ce2a)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- (**generator**) handle computed and optional differently - ([1041ac9](https://gitlab.com/TECHNOFAB/tofunix/commit/1041ac9ca7b79813388840f1ca914e8731e9ddaf)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- (**gitlab**) switch to pkgs.fetchurl - ([721910e](https://gitlab.com/TECHNOFAB/tofunix/commit/721910eb3023840d08d075b9c54d1ade4706b87d)) - TECHNOFAB
- (**packaging**) cacert missing broke curl, improve error handling - ([7e69a32](https://gitlab.com/TECHNOFAB/tofunix/commit/7e69a329f4810c2e833f6cb27ac816b1af1c5f9c)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- switch from ln to copy so pure eval is possible - ([bc14eef](https://gitlab.com/TECHNOFAB/tofunix/commit/bc14eef960fa380ec516efab25440213b8628113)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- *sigh* also add missing curl - ([5092334](https://gitlab.com/TECHNOFAB/tofunix/commit/5092334b7004f7a93c7c1c85417efe8674a6d490)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Documentation
- (**README**) typo - ([bfb2ef9](https://gitlab.com/TECHNOFAB/tofunix/commit/bfb2ef9d68fec2bb21a09e596fd720a46e03a488)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- add license, improve README and docs introduction - ([7b242b3](https://gitlab.com/TECHNOFAB/tofunix/commit/7b242b3658d8603ff06f45509963aa8ab32e0d31)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- add a bunch of documentation - ([caf5b66](https://gitlab.com/TECHNOFAB/tofunix/commit/caf5b6643abf4f871ca819720c3a6814be7ff214)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- only send analytics on correct domain - ([985b9ff](https://gitlab.com/TECHNOFAB/tofunix/commit/985b9ff01659dc63ac99ae4f6467d5d7388c5cab)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- add favicon - ([77e80df](https://gitlab.com/TECHNOFAB/tofunix/commit/77e80df972caff338e157e39c94cde0e5eac1249)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Refactoring
- ![BREAKING](https://img.shields.io/badge/BREAKING-red) (**lib**) minor improvements, restructure module - ([967eb89](https://gitlab.com/TECHNOFAB/tofunix/commit/967eb89b00003a958fd1e1c9a0616dd038743e9b)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- minor style improvements - ([4d63aa8](https://gitlab.com/TECHNOFAB/tofunix/commit/4d63aa8dee04e185654c619b304ab52630676062)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
#### Miscellaneous Chores
- (**cli**) passthru tfjson for easy access - ([b6942cc](https://gitlab.com/TECHNOFAB/tofunix/commit/b6942cc78d54ad536375043e8b948eae5b74b0d9)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- (**gitlab**) remove chmod +x as its not needed - ([f58befb](https://gitlab.com/TECHNOFAB/tofunix/commit/f58befb1bc3527126c65e76f6319c1ac74507098)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- add fully featured template - ([2336ca3](https://gitlab.com/TECHNOFAB/tofunix/commit/2336ca312cf62a5a8ef479c3ebc43e4dcd13e9bb)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- add initial docs - ([d444b1b](https://gitlab.com/TECHNOFAB/tofunix/commit/d444b1b4ac954e0b0ec27f4bf6c6606b1d4b56d8)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- cleanup - ([1ab73f4](https://gitlab.com/TECHNOFAB/tofunix/commit/1ab73f451251613341efdd19a50753802fa77447)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- initial references improvement - ([518240f](https://gitlab.com/TECHNOFAB/tofunix/commit/518240f793e3a0d224ad73ff8b7ba37b46880577)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- allow references everywhere and improve multi arch provider generation - ([6eae98b](https://gitlab.com/TECHNOFAB/tofunix/commit/6eae98b35296bd9788b7207ac91798777dee7773)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- roughly implement tofunix lib - ([9ba11db](https://gitlab.com/TECHNOFAB/tofunix/commit/9ba11db726a54c67669678bab58125e3d9fd9b17)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)
- initial commit / draft - ([7a355b7](https://gitlab.com/TECHNOFAB/tofunix/commit/7a355b7cf4001515249157548dd4f608d44a9252)) - [@TECHNOFAB](https://gitlab.com/TECHNOFAB)

- - -

Changelog generated by [cocogitto](https://github.com/cocogitto/cocogitto).
