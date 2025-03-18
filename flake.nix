{
    inputs =
        {
            flake-utils.url = "github:numtide/flake-utils" ;
            nixpkgs.url = "github:NixOs/nixpkgs" ;
            visitor.url = "github:viktordanek/visitor" ;
        } ;
    outputs =
        { flake-utils , nixpkgs , self , visitor } :
            let
                fun =
                    system :
                        let
                            lib =
                                {
                                    environment ? x : [ ] ,
                                    extensions ? [ ] ,
                                    script ,
                                    tests ? null
                                } :
                                    let
                                        primary =
                                            {
                                                environment =
                                                    if builtins.typeOf environment == "lambda" then
                                                        if builtins.typeOf environment primary.extensions == "list" then
                                                            builtins.map ( e : if builtins.typeOf e == "string" then e else builtins.throw "environment is not string but ${ builtins.typeOf e }." ) environment primary.extensions
                                                        else builtins.throw "environments is not list but ${ builtins.typeOf ( environment primary.extension ) }."
                                                    else builtins.throw "environments is not lambda but ${ builtins.typeOf environment }." ;
                                                extensions =
                                                    if builtins.typeOf extensions == "list" then
                                                        builtins.map ( e : if builtins.typeOf e == "lambda" then e else builtins.throw "extension is not lambda but ${ builtins.typeOf e }." ) extensions
                                                    else builtins.throw "extensions is not list but ${ builtins.typeOf extensions }." ;
                                                script =
                                                    if builtins.typeOf script == "string" then script
                                                    else builtins.throw "script is not string but ${ builtins.typeOf script }." ;
                                                tests =
                                                    if builtins.typeOf tests == "null" then tests
                                                    else if builtins.typeOf tests == "lambda" then tests
                                                    else if builtins.typeOf tests == "list" then tests
                                                    else if builtins.typeOf tests == "set" then tests
                                                    else builtins.throw "tests is not null, lambda, list, set but ${ builtins.typeOf tests }." ;
                                            } ;
                                        in
                                            {
                                                source =
                                                    pkgs.stdenv.mkDerivation
                                                        {
                                                            installPhase =
                                                                ''
                                                                    ${ pkgs.coreutils }/bin/cat $src > $out &&
                                                                        ${ pkgs.coreutils }/bin/chmod 0555 $out
                                                                '' ;
                                                            name = "source" ;
                                                            src = script ;
                                                            unpack = true ;
                                                        } ;
                                                shell-script =
                                                    pkgs.stdenv.mkDerivation
                                                        {
                                                            installPhase =
                                                                let
                                                                    in
                                                                        ''
                                                                            makeWrapper $src $out ${ builtins.concatStringsSep " " ( environment extensions ) }
                                                                        '' ;
                                                            name = "shell-script" ;
                                                            nativeBuildInputs = [ pkgs.makeWrapper ] ;
                                                            src = ./. ;
                                                            unpack = false ;
                                                        } ;
                                                tests =
                                                    pkgs.stdenv.mkDerivation
                                                        {
                                                            installPhase =
                                                                let
                                                                    _visitor = builtins.getAttr system visitor.lib ;
                                                                    constructors =
                                                                        _visitor
                                                                            {
                                                                                null = path : value : [ ] ;
                                                                            }
                                                                            {
                                                                                list =
                                                                                    path : list :
                                                                                        builtins.concatLists
                                                                                            [
                                                                                                [
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStrings ( builtins.concatLists ( [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) ) ) }"
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStrings ( builtins.concatLists ( [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) ) ) }"
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStrings ( builtins.concatLists ( [ "$out" "test" ] ( builtins.map builtins.toJSON path ) ) ) }"
                                                                                                ]
                                                                                                ( builtins.concatLists list )
                                                                                            ] ;
                                                                                set =
                                                                                    path : set :
                                                                                        builtins.concatLists
                                                                                            [
                                                                                                [
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStrings ( builtins.concatLists ( [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) ) ) }"
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStrings ( builtins.concatLists ( [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) ) ) }"
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStrings ( builtins.concatLists ( [ "$out" "test" ] ( builtins.map builtins.toJSON path ) ) ) }"
                                                                                                ]
                                                                                                ( builtins.concatLists ( builtins.attrValues set ) )
                                                                                            ] ;
                                                                            }
                                                                            tests ;
                                                                    in builtins.concatStringsSep " &&\n\t" ( builtins.concatLists [ [ "${ pkgs.coreutils }/bin/mkdir $out" ] constructors ] ) ;
                                                            name = "tests" ;
                                                            src = script ;
                                                            unpack = true ;
                                                        } ;
                                            } ;
                            pkgs = builtins.import nixpkgs { system = system ; } ;
                            in
                                {
                                    checks =
                                        {
                                            foobar =
                                                pkgs.stdenv.mkDerivation
                                                    {
                                                        installPhase =
                                                            let
                                                                shell-script =
                                                                    lib
                                                                        {
                                                                            script = self + "/scripts/foobar.sh" ;
                                                                        } ;
                                                                in
                                                                    ''
                                                                        ${ pkgs.coreutils }/bin/touch $out &&
                                                                            exit 55
                                                                    '' ;
                                                        name = "foobar" ;
                                                        src = ./. ;
                                                    } ;
                                        } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}