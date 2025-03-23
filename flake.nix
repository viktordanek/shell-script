{
    inputs =
        {
            environment-variable.url = "github:viktordanek/environment-variable" ;
            flake-utils.url = "github:numtide/flake-utils" ;
            nixpkgs.url = "github:NixOs/nixpkgs" ;
            visitor.url = "github:viktordanek/visitor" ;
        } ;
    outputs =
        { environment-variable , flake-utils , nixpkgs , self , visitor } :
            let
                fun =
                    system :
                        let
                            lib =
                                {
                                    environment ? x : [ ] ,
                                    extensions ? [ ] ,
                                    name ,
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
                                                    if builtins.typeOf extensions == "set" then
                                                        builtins.mapAttr ( name : value : if builtins.typeOf value == "lambda" then value else builtins.throw "extension is not lambda but ${ builtins.typeOf value }." ) extensions
                                                    else builtins.throw "extensions is not set but ${ builtins.typeOf extensions }." ;
                                                name =
                                                    if builtins.typeOf name == "string" then
                                                        if pkgs.lib.strings.match "^[a-zA-Z_][a-zA-Z0-9_-]*$" name != null then name
                                                        else builtins.throw "the name (${ name }) is not suitable for a bash script."
                                                    else builtins.throw "name is not string but ${ builtins.typeOf name }." ;
                                                script =
                                                    if builtins.typeOf script == "string" then
                                                        if builtins.pathExists script then script
                                                        else builtins.throw "there is no path for ${ script }."
                                                    else builtins.throw "script is not string but ${ builtins.typeOf script }." ;
                                                tests =
                                                    if builtins.typeOf tests == "null" then tests
                                                    else if builtins.typeOf tests == "list" then tests
                                                    else if builtins.typeOf tests == "set" then tests
                                                    else builtins.throw "tests is not null, list, set but ${ builtins.typeOf tests }." ;
                                            } ;
                                        shell-script =
                                            name :
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
                                                                        ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                            ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                            makeWrapper ${ source } $out/bin/${ name } ${ builtins.concatStringsSep " " ( environment extensions ) }
                                                                    '' ;
                                                        name = name ;
                                                        nativeBuildInputs = [ pkgs.makeWrapper ] ;
                                                        src = ./. ;
                                                    } ;
                                        in
                                            {
                                                shell-script = "${ shell-script primary.name }/bin/${ primary.name }" ;
                                                tests =
                                                    pkgs.stdenv.mkDerivation
                                                        {
                                                            installPhase =
                                                                let
                                                                    _environment-variable = builtins.getAttr system environment-variable.lib ;
                                                                    _visitor = builtins.getAttr system visitor.lib ;
                                                                    constructors =
                                                                        _visitor
                                                                            {
                                                                                lambda =
                                                                                    path : value :
                                                                                        let
                                                                                            derivation =
                                                                                                pkgs.stdenv.mkDerivation
                                                                                                    {
                                                                                                        installPhase =
                                                                                                            let
                                                                                                                constructors =
                                                                                                                    builtins.concatLists
                                                                                                                        [
                                                                                                                            ( builtins.map ( { index , is-file , ... } : "${ _environment-variable ( if is-file then "TOUCH" else "MKDIR" ) } /build/mounts.${ index }" ) secondary.mounts )
                                                                                                                            ( builtins.map ( { index , is-file , ... } : "${ _environment-variable "CHMOD" } 0777 /build/mounts.${ index }" ) secondary.mounts )
                                                                                                                            # ( builtins.map ( { index , is-file , ... } : "${ _environment-variable "ECHO" } hi | tee /build/mounts.${ index }" ) secondary.mounts )
                                                                                                                            [
                                                                                                                                "echo BEFORE >> ${ _environment-variable "OUT" }/debug"
                                                                                                                            ]
                                                                                                                            ( builtins.map ( { index , name , ... } : ''echo -en "\n\n${ name }\n$( cat /build/mounts.${ index } )\n$( stat /build/mounts.${ index } )\n" >> ${ _environment-variable "OUT" }/debug'' ) secondary.mounts )
                                                                                                                            (
                                                                                                                                let
                                                                                                                                    mapper =
                                                                                                                                        { index , initial , name , ... } :
                                                                                                                                            let
                                                                                                                                                user-environment =
                                                                                                                                                    pkgs.buildFHSUserEnv
                                                                                                                                                        {
                                                                                                                                                            extraBwrapArgs = [ "--bind /build/mounts.${ index } /mount" ] ;
                                                                                                                                                            name = "initial" ;
                                                                                                                                                            runScript = pkgs.writeShellScript "initial" initial ;
                                                                                                                                                            targetPkgs = pkgs : [ pkgs.coreutils ] ;
                                                                                                                                                        } ;
                                                                                                                                                in "( ${ user-environment }/bin/initial >> ${ _environment-variable "OUT" }/debug 2>&1 || true )" ;
                                                                                                                                    in builtins.map mapper secondary.mounts
                                                                                                                            )
                                                                                                                            [
                                                                                                                                "echo AFTER >> ${ _environment-variable "OUT" }/debug"
                                                                                                                            ]
                                                                                                                            ( builtins.map ( { index , name , ... } : ''echo -en "\n\n${ name }\n$( cat /build/mounts.${ index } )\n" >> ${ _environment-variable "OUT" }/debug'' ) secondary.mounts )
                                                                                                                            [
                                                                                                                                "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/test"
                                                                                                                                "${ _environment-variable "LN" } --symbolic ${ pkgs.writeShellScript "run-script" ( builtins.concatStringsSep " &&\n\t" secondary.test ) } ${ _environment-variable "OUT" }/test/run-script.sh"
                                                                                                                                "source ${ _environment-variable "MAKE_WRAPPER" }/nix-support/setup-hook"
                                                                                                                                "makeWrapper ${ _environment-variable "OUT" }/test/run-script.sh ${ _environment-variable "OUT" }/test/run-script --set PATH ${ pkgs.coreutils }:${ shell-script "candidate" }/bin"
                                                                                                                            ]
                                                                                                                            [
                                                                                                                                "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/observed"
                                                                                                                                (
                                                                                                                                    let
                                                                                                                                        user-environment =
                                                                                                                                            pkgs.buildFHSUserEnv
                                                                                                                                                {
                                                                                                                                                    extraBwrapArgs = builtins.map ( { index , name , ... } : "--bind /build/mounts.${ index } ${ name }" ) secondary.mounts ;
                                                                                                                                                    name = "observe" ;
                                                                                                                                                    runScript = "${ _environment-variable "OUT" }/test/run-script" ;
                                                                                                                                                } ;
                                                                                                                                        in "${ user-environment }/bin/observe > ${ _environment-variable "OUT" }/observed/standard-input 2> ${ _environment-variable "OUT" }/observed/standard-error"
                                                                                                                                )
                                                                                                                                "${ _environment-variable "ECHO" } ${ _environment-variable "?" } > ${ _environment-variable "OUT" }/observed/status"
                                                                                                                            ]
                                                                                                                            [
                                                                                                                                "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/expected"
                                                                                                                                "${ _environment-variable "LN" } --symbolic ${ secondary.standard-output } ${ _environment-variable "OUT" }/expected/standard-output"
                                                                                                                            ]
                                                                                                                            (
                                                                                                                                let
                                                                                                                                    mapper =
                                                                                                                                        { index , ... } :
                                                                                                                                            "${ _environment-variable "MV" } /build/mounts.${ index } ${ _environment-variable "OUT" }/observed/mounts.${ index } >> ${ _environment-variable "OUT" }/debug" ;
                                                                                                                                    in builtins.map mapper secondary.mounts
                                                                                                                            )
                                                                                                                        ] ;
                                                                                                                in
                                                                                                                ''
                                                                                                                    ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                                                        ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                                                                        ${ pkgs.coreutils }/bin/ln --symbolic ${ pkgs.writeShellScript "constructors" ( builtins.concatStringsSep " &&\n\t" constructors ) } $out/bin/constructors.sh &&
                                                                                                                        makeWrapper $out/bin/constructors.sh $out/bin/constructors --set CHMOD ${ pkgs.coreutils }/bin/chmod --set ECHO ${ pkgs.coreutils }/bin/echo --set LN ${ pkgs.coreutils }/bin/ln --set MAKE_WRAPPER ${ pkgs.makeWrapper } --set MKDIR ${ pkgs.coreutils }/bin/mkdir --set MV ${ pkgs.coreutils }/bin/mv --set OUT $out --set TOUCH ${ pkgs.coreutils }/bin/touch &&
                                                                                                                        $out/bin/constructors
                                                                                                                '' ;
                                                                                                        name = "test" ;
                                                                                                        nativeBuildInputs = [ pkgs.makeWrapper ] ;
                                                                                                        src = ./. ;
                                                                                                    } ;
                                                                                            secondary =
                                                                                                let
                                                                                                    identity =
                                                                                                        {
                                                                                                            mounts ? { } ,
                                                                                                            standard-error ? "" ,
                                                                                                            standard-output ? "" ,
                                                                                                            status ? 0 ,
                                                                                                            test
                                                                                                        } :
                                                                                                            {
                                                                                                                 mounts =
                                                                                                                    if builtins.typeOf mounts == "set" then
                                                                                                                        let
                                                                                                                            generator =
                                                                                                                                index :
                                                                                                                                    let
                                                                                                                                        elem = builtins.elemAt list index ;
                                                                                                                                        list =
                                                                                                                                            let
                                                                                                                                                set =
                                                                                                                                                    let
                                                                                                                                                        mapper =
                                                                                                                                                            name : { expected , initial ? "" , is-file ? true} :
                                                                                                                                                                {
                                                                                                                                                                    initial =
                                                                                                                                                                        if builtins.typeOf initial == "string" then
                                                                                                                                                                            if builtins.match "^/.*" initial == null then initial
                                                                                                                                                                            else
                                                                                                                                                                                if builtins.pathExists initial then initial
                                                                                                                                                                                else builtins.throw "there is no path for ${ initial }."
                                                                                                                                                                        else builtins.throw "initial is not null, string but ${ builtins.typeOf initial }." ;
                                                                                                                                                                    is-file =
                                                                                                                                                                        if builtins.typeOf is-file == "bool" then is-file
                                                                                                                                                                        else builtins.throw "is-file is not bool but ${ builtins.typeOf is-file }." ;
                                                                                                                                                                    expected =
                                                                                                                                                                        if builtins.typeOf expected == "string" then
                                                                                                                                                                            if builtins.pathExists expected then expected
                                                                                                                                                                            else builtins.throw "there is no path for ${ expected }."
                                                                                                                                                                        else builtins.throw "expected is not string but ${ builtins.typeOf expected }." ;
                                                                                                                                                                    name = name ;
                                                                                                                                                                } ;
                                                                                                                                                        in builtins.mapAttrs mapper mounts ;
                                                                                                                                                in builtins.attrValues set ;
                                                                                                                                        in
                                                                                                                                            {
                                                                                                                                                index = builtins.toString index ;
                                                                                                                                                initial = elem.initial ;
                                                                                                                                                is-file = elem.is-file ;
                                                                                                                                                expected = elem.expected ;
                                                                                                                                                name = elem.name ;
                                                                                                                                            } ;
                                                                                                                            in builtins.genList generator ( builtins.length ( builtins.attrNames mounts ) )
                                                                                                                    else builtins.throw "mounts is not set but ${ builtins.typeOf mounts }." ;
                                                                                                                standard-error =
                                                                                                                    if builtins.typeOf standard-error == "string" then
                                                                                                                        if builtins.match "^/.*" standard-error != null then
                                                                                                                            if builtins.pathExists standard-error then standard-error
                                                                                                                            else builtins.throw "standard-error is an absolute path but there does not exist a path for ${ standard-error }."
                                                                                                                        else builtins.toFile "standard-error" standard-error
                                                                                                                    else builtins.throw "standard-error is not string but ${ builtins.typeOf standard-error }." ;
                                                                                                                standard-output =
                                                                                                                    if builtins.typeOf standard-output == "string" then
                                                                                                                        if builtins.match "^/.*" standard-output != null then
                                                                                                                            if builtins.pathExists standard-output then standard-output
                                                                                                                            else builtins.throw "standard-output is an absolute path but there does not exist a path for ${ standard-output }."
                                                                                                                        else builtins.toFile "standard-output" standard-output
                                                                                                                    else builtins.throw "standard-output is not string but ${ builtins.typeOf standard-output }." ;
                                                                                                                status =
                                                                                                                    if builtins.typeOf status == "int" then builtins.toString status
                                                                                                                    else builtins.throw "status is not int but ${ builtins.typeOf status }." ;
                                                                                                                test =
                                                                                                                    if builtins.typeOf test == "string" then [ test ]
                                                                                                                    else if builtins.typeOf test == "list" then
                                                                                                                        let
                                                                                                                            mapper = value : if builtins.typeOf value == "string" then value else builtins.throw "test is not string but ${ builtins.typeOf value }." ;
                                                                                                                            in builtins.map mapper test
                                                                                                                    else builtins.throw "test is not string but ${ builtins.typeOf test }." ;
                                                                                                            } ;
                                                                                                in identity ( value null ) ;
                                                                                            in
                                                                                                [
                                                                                                    "${ _environment-variable "LN" } --symbolic ${ derivation } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ ( _environment-variable "OUT" ) "links" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                ] ;
                                                                                null = path : value : [ ] ;
                                                                            }
                                                                            {
                                                                                list =
                                                                                    path : list :
                                                                                        builtins.concatLists
                                                                                            [
                                                                                                [
                                                                                                    "${ _environment-variable "MKDIR" } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ ( _environment-variable "OUT" ) "links" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                ]
                                                                                                ( builtins.concatLists list )
                                                                                            ] ;
                                                                                set =
                                                                                    path : set :
                                                                                        builtins.concatLists
                                                                                            [
                                                                                                [
                                                                                                    "${ _environment-variable "MKDIR" } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ ( _environment-variable "OUT" ) "links" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                ]
                                                                                                ( builtins.concatLists ( builtins.attrValues set ) )
                                                                                            ] ;
                                                                            }
                                                                            tests ;
                                                                    in
                                                                        ''
                                                                            ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                                ${ pkgs.coreutils }/bin/ln --symbolic ${ pkgs.writeShellScript "constructors.sh" ( builtins.concatStringsSep " &&\n\t" constructors ) } $out/bin/constructors.sh &&
                                                                                makeWrapper $out/bin/constructors.sh $out/bin/constructors --set LN ${ pkgs.coreutils }/bin/ln --set MKDIR ${ pkgs.coreutils }/bin/mkdir --set OUT $out &&
                                                                                $out/bin/constructors
                                                                        '';
                                                            name = "tests" ;
                                                            nativeBuildInputs = [ pkgs.makeWrapper ] ;
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
                                                                no-tests =
                                                                    lib
                                                                        {
                                                                            environment =
                                                                                { string } :
                                                                                    [
                                                                                        ( string "CAT" "${ pkgs.coreutils }/bin/cat" )
                                                                                        ( string "CHMOD" "${ pkgs.coreutils }/bin/chmod" )
                                                                                        ( string "ECHO" "${ pkgs.coreutils }/bin/echo" )
                                                                                    ] ;
                                                                            extensions =
                                                                                {
                                                                                    string = name : value : "--set ${ name } ${ value }" ;
                                                                                } ;
                                                                            name = "foobar" ;
                                                                            script = self + "/scripts/foobar.sh" ;
                                                                        } ;
                                                                shell-script =
                                                                    lib
                                                                        {
                                                                            environment =
                                                                                { string } :
                                                                                    [
                                                                                        ( string "CAT" "${ pkgs.coreutils }/bin/cat" )
                                                                                        ( string "CHMOD" "${ pkgs.coreutils }/bin/chmod" )
                                                                                        ( string "ECHO" "${ pkgs.coreutils }/bin/echo" )
                                                                                    ] ;
                                                                            extensions =
                                                                                {
                                                                                    string = name : value : "--set ${ name } ${ value }" ;
                                                                                } ;
                                                                            name = "foobar" ;
                                                                            script = self + "/scripts/foobar.sh" ;
                                                                            tests =
                                                                                {
                                                                                    file =
                                                                                        ignore :
                                                                                            {
                                                                                                mounts =
                                                                                                    {
                                                                                                        singleton =
                                                                                                            {
                                                                                                                expected = self + "/mounts/expected" ;
                                                                                                                initial = "echo DURING && cat /mount && stat /mount" ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                standard-error = self + "/expected/standard-error" ;
                                                                                                standard-output = self + "/expected/standard-output" ;
                                                                                                status = 96 ;
                                                                                                test = "candidate" ;
                                                                                            } ;
                                                                                } ;
                                                                        } ;
                                                                in
                                                                    ''
                                                                        ${ pkgs.coreutils }/bin/touch $out &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ shell-script.shell-script } &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ shell-script.tests } &&
                                                                            exit 45
                                                                    '' ;
                                                        name = "foobar" ;
                                                        src = ./. ;
                                                    } ;
                                        } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}