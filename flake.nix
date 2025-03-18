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
                                                shell-script =
                                                    pkgs.stdenv.mkDerivation
                                                        {
                                                            installPhase =
                                                                let
                                                                    source =
                                                                        pkgs.stdenv.mkDerivation
                                                                            {
                                                                                installPhase = "${ pkgs.coreutils }/bin/install -D --mode 555 ${ script } $out" ;
                                                                                name = "source" ;
                                                                                src = ./. ;
                                                                            } ;
                                                                    in
                                                                        ''
                                                                            makeWrapper ${ source } $out ${ builtins.concatStringsSep " " ( environment extensions ) }
                                                                        '' ;
                                                            name = "shell-script" ;
                                                            nativeBuildInputs = [ pkgs.makeWrapper ] ;
                                                            src = ./. ;
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
                                                                                lambda =
                                                                                    path : value :
                                                                                        let
                                                                                            secondary =
                                                                                                let
                                                                                                    identity =
                                                                                                        {
                                                                                                            arguments ? [ ] ,
                                                                                                            count ? 2 ,
                                                                                                            file ? null ,
                                                                                                            pipe ? null ,
                                                                                                            paste ? null ,
                                                                                                            status ? 0
                                                                                                        } :
                                                                                                            {
                                                                                                                arguments =
                                                                                                                    if builtins.typeOf arguments == "list" then
                                                                                                                        builtins.map ( a : if builtins.typeOf a == "string" then a else builtins.throw "argument is not string but ${ builtins.typeOf a }." ) arguments
                                                                                                                    else builtins.throw "arguments is not list but ${ builtins.typeOf arguments }." ;
                                                                                                                count =
                                                                                                                    if builtins.typeOf count == "int" then
                                                                                                                        if count >= 0 then count
                                                                                                                        else builtins.throw "count ${ count } is negative"
                                                                                                                    else builtins.throw "count is not int but ${ builtins.typeOf count }." ;
                                                                                                                file =
                                                                                                                    if builtins.typeOf file == "null" then file
                                                                                                                    else if builtins.typeOf file == "string" then
                                                                                                                        let
                                                                                                                            eval = builtins.toFile "file" file ;
                                                                                                                            in if eval.success == true then eval.value else builtins.throw "file (${ file }) is not a string that can be filed"
                                                                                                                    else builtins.throw "file is not null, string but ${ builtins.typeOf file }." ;
                                                                                                                pipe =
                                                                                                                    if builtins.typeOf pipe == "null" then pipe
                                                                                                                    else if builtins.typeOf pipe == "string" then
                                                                                                                        let
                                                                                                                            eval = builtins.toFile "pipe" pipe ;
                                                                                                                            in if eval.success == true then eval.value else builtins.throw "pipe (${ pipe }) is not a string that be filed."
                                                                                                                    else builtins.throw "pipe is not null, string but ${ builtins.typeOf pipe }." ;
                                                                                                                paste =
                                                                                                                    if builtins.typeOf paste == "lambda" then
                                                                                                                        let
                                                                                                                            generator =
                                                                                                                                index :
                                                                                                                                    let
                                                                                                                                        eval = builtins.tryEval ( paste variable ) ;
                                                                                                                                        success =
                                                                                                                                            if eval.success then
                                                                                                                                                if builtins.typeOf eval.value == "string" then eval.variable
                                                                                                                                                else builtins.throw "paste of ${ variable } is not string but ${ builtins.typeOf eval.value }."
                                                                                                                                            else builtins.throw "paste can not evaluate ${ variable }." ;
                                                                                                                                        variable = builtins.concatStringsSep "" [ "$" "{" "VARIABLE_" ( builtins.toString index ) "}" ] ;
                                                                                                                                        in success ;
                                                                                                                            in builtins.genList generator secondary.count
                                                                                                                    else if builtins.typeOf paste == "null" then paste
                                                                                                                    else builtins.throw "paste is not lambda, null but ${ builtins.typeOf paste }." ;
                                                                                                                status =
                                                                                                                    if builtins.typeOf status == "int" then builtins.toString status
                                                                                                                    else builtins.throw "status is not int but ${ builtins.typeOf status }." ;
                                                                                                            } ;
                                                                                                in identity ( value null ) ;
                                                                                            in
                                                                                                [
                                                                                                    (
                                                                                                        let
                                                                                                            test = builtins.toFile "test" "" ;
                                                                                                            in
                                                                                                                "${ pkgs.coreutils }/bin/ln --symbolic ${ test } ${ builtins.concatStringsSep "" ( builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                    )
                                                                                                ] ;
                                                                                null = path : value : [ ] ;
                                                                            }
                                                                            {
                                                                                list =
                                                                                    path : list :
                                                                                        builtins.concatLists
                                                                                            [
                                                                                                [
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "" ( builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "" ( builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "" ( builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                ]
                                                                                                ( builtins.concatLists list )
                                                                                            ] ;
                                                                                set =
                                                                                    path : set :
                                                                                        builtins.concatLists
                                                                                            [
                                                                                                [
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                ]
                                                                                                ( builtins.concatLists ( builtins.attrValues set ) )
                                                                                            ] ;
                                                                            }
                                                                            tests ;
                                                                    in builtins.concatStringsSep " &&\n\t" ( builtins.concatLists [ [ "${ pkgs.coreutils }/bin/mkdir $out" ] constructors ] ) ;
                                                            name = "tests" ;
                                                            src = ./. ;
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
                                                                            tests =
                                                                                ignore : { } ;
                                                                        } ;
                                                                in
                                                                    ''
                                                                        ${ pkgs.coreutils }/bin/touch $out &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ shell-script.shell-script } &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ shell-script.tests } &&
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