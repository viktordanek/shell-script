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
                                                                                                                            ( builtins.map ( mount : mount.create ) secondary.mounts )
                                                                                                                            [
                                                                                                                                "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/test"
                                                                                                                                "${ _environment-variable "LN" } --symbolic ${ pkgs.writeShellScript "run-script" ( builtins.concatStringsSep " " ( builtins.concatLists [ secondary.pipe [ "candidate" ] secondary.arguments secondary.file ] ) ) } ${ _environment-variable "OUT" }/test/run-script.sh"
                                                                                                                                "source ${ _environment-variable "MAKE_WRAPPER" }/nix-support/setup-hook"
                                                                                                                                "makeWrapper $out/bin/run-script.sh $out/test/run-script --set PATH ${ pkgs.coreutils }"
                                                                                                                                (
                                                                                                                                    let
                                                                                                                                        user-environment =
                                                                                                                                            pkgs.buildFHSUserEnv
                                                                                                                                                {
                                                                                                                                                    extraBwrapArgs = builtins.map ( mount : mount.bind ) secondary.mounts ;
                                                                                                                                                    name = "user-environment" ;
                                                                                                                                                    runScript = "${ _environment-variable "OUT" }/test/run-script" ;
                                                                                                                                                    targetPkgs = targetPkgs : [ ( shell-script "candidate" ) ] ;
                                                                                                                                                } ;
                                                                                                                                        in "${ _environment-variable "LN" } --symbolic ${ user-environment } ${ _environment-variable "OUT" }/test/user-environment"
                                                                                                                                )
                                                                                                                            ]
                                                                                                                            # ( builtins.concatLists ( builtins.map ( mount : mount.wrap ) secondary.mounts ) )
                                                                                                                            [
                                                                                                                                "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/observed"
                                                                                                                            ]
                                                                                                                            [
                                                                                                                                "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/expected"
                                                                                                                            ]
                                                                                                                        ] ;
                                                                                                                in
                                                                                                                ''
                                                                                                                    ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                                                        ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                                                                        ${ pkgs.coreutils }/bin/ln --symbolic ${ pkgs.writeShellScript "constructors" ( builtins.concatStringsSep " &&\n\t" constructors ) } $out/bin/constructors.sh &&
                                                                                                                        makeWrapper $out/bin/constructors.sh $out/bin/constructors --set LN ${ pkgs.coreutils }/bin/ln --set MAKE_WRAPPER ${ pkgs.makeWrapper } --set MKDIR ${ pkgs.coreutils }/bin/mkdir --set OUT $out &&
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
                                                                                                            arguments ? [ ] ,
                                                                                                            file ? null ,
                                                                                                            mounts ? { } ,
                                                                                                            pipe ? null ,
                                                                                                            standard-error ? "" ,
                                                                                                            standard-output ? "" ,
                                                                                                            status ? 0
                                                                                                        } :
                                                                                                            {
                                                                                                                arguments =
                                                                                                                    if builtins.typeOf arguments == "list" then
                                                                                                                        builtins.map ( a : if builtins.typeOf a == "string" then a else builtins.throw "argument is not string but ${ builtins.typeOf a }." ) arguments
                                                                                                                    else builtins.throw "arguments is not list but ${ builtins.typeOf arguments }." ;
                                                                                                                file =
                                                                                                                    if builtins.typeOf file == "null" then [ ]
                                                                                                                    else if builtins.typeOf file == "string" then
                                                                                                                        let
                                                                                                                            eval = builtins.toFile "file" file ;
                                                                                                                            in if eval.success == true then [ "<" eval.value ] else builtins.throw "file (${ file }) is not a string that can be filed"
                                                                                                                    else builtins.throw "file is not null, string but ${ builtins.typeOf file }." ;
                                                                                                                mounts =
                                                                                                                    if builtins.typeOf mounts == "set" then
                                                                                                                        let
                                                                                                                            generator =
                                                                                                                                index :
                                                                                                                                    let
                                                                                                                                        mapper =
                                                                                                                                            name : { expected , initial ? null } :
                                                                                                                                                {
                                                                                                                                                    initial =
                                                                                                                                                        if builtins.typeOf initial == "null" then initial
                                                                                                                                                        else if builtins.typeOf initial == "string" then
                                                                                                                                                            if builtins.pathExists initial then initial
                                                                                                                                                            else builtins.throw "there is no path for ${ initial }."
                                                                                                                                                        else builtins.throw "initial is not null, string but ${ builtins.typeOf initial }." ;
                                                                                                                                                    expected =
                                                                                                                                                        if builtins.typeOf expected == "string" then
                                                                                                                                                            if builtins.pathExists expected then expected
                                                                                                                                                            else builtins.throw "there is no path for ${ expected }."
                                                                                                                                                        else builtins.throw "expected is not string but ${ builtins.typeOf expected }." ;
                                                                                                                                                    name = name ;
                                                                                                                                                } ;
                                                                                                                                        mount = builtins.elemAt index ( builtins.attrValues ( builtins.mapAttrs mapper mount ) ) ;
                                                                                                                                        in
                                                                                                                                            {
                                                                                                                                                bind = "--bind ${ _environment-variable "MOUNT_${ builtins.toString index }" } /${ name }" ;
                                                                                                                                                create = "export MOUNT_${ builtins.toString index }=/build/mounts.${ builtins.toString index }" ;
                                                                                                                                                wrap =
                                                                                                                                                    if builtins.typeOf mount.initial == "null" then [ ]
                                                                                                                                                    else
                                                                                                                                                        [
                                                                                                                                                            "${ pkgs.coreutils }/bin/ln --symbolic ${ mount.initial } ${ environment-variable "OUT" }/test/mount.${ builtins.toString index }.sh"
                                                                                                                                                            "makeWrapper ${ environment-variable "OUT" }/test/mount.${ builtins.toString index }.sh ${ environment-variable "OUT" }/test/mount.${ builtins.toString index } --set MOUNT ${ environment-variable "MOUNT_${ builtins.toString index }" }"
                                                                                                                                                        ] ;
                                                                                                                                            } ;
                                                                                                                            in builtins.genList generator ( builtins.length ( builtins.attrNames mounts ) )
                                                                                                                    else builtins.throw "mounts is not set but ${ builtins.typeOf mounts }." ;
                                                                                                                pipe =
                                                                                                                    if builtins.typeOf pipe == "null" then [ ]
                                                                                                                    else if builtins.typeOf pipe == "string" then
                                                                                                                        let
                                                                                                                            eval = builtins.toFile "pipe" pipe ;
                                                                                                                            in if eval.success == true then [ "cat" eval.value "|" ] else builtins.throw "pipe (${ pipe }) is not a string that be filed."
                                                                                                                    else builtins.throw "pipe is not null, string but ${ builtins.typeOf pipe }." ;
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
                                                                                # --set CAT ${ pkgs.coreutils }/bin/cat --set CHMOD ${ pkgs.coreutils }/bin/chmod --set CP ${ pkgs.coreutils }/bin/cp --set ECHO ${ pkgs.coreutils }/bin/echo --set EXPECTED $out/expected --set MKDIR ${ pkgs.coreutils }/bin/mkdir --set OBSERVED $out/observed --set RM ${ pkgs.coreutils }/bin/rm --set TEST $out/test &&
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
                                                                                                                initial = self + "/mounts/initial" ;
                                                                                                                permissions =
                                                                                                                    {
                                                                                                                        file = 777 ;
                                                                                                                    } ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                standard-error = self + "/expected/standard-error" ;
                                                                                                standard-output = self + "/expected/standard-output" ;
                                                                                                status = 96 ;
                                                                                            } ;
                                                                                    null =
                                                                                        ignore :
                                                                                            {
                                                                                                mounts =
                                                                                                    {
                                                                                                        singleton =
                                                                                                            {
                                                                                                                expected = self + "/mounts/expected" ;
                                                                                                                initial = self + "/mounts/initial" ;
                                                                                                                permissions =
                                                                                                                    {
                                                                                                                        file = 777 ;
                                                                                                                    } ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                standard-error = "standard-error 6641672962c2fdb4d4a3686c119c74dd89164f7e489a75008b514b668347b004de670b3e4ad7d5010599a103743c7febb4d767901e78298933a42d16642c7060" ;
                                                                                                standard-output = "standard-output 6641672962c2fdb4d4a3686c119c74dd89164f7e489a75008b514b668347b004de670b3e4ad7d5010599a103743c7febb4d767901e78298933a42d16642c7060";
                                                                                                status = 96 ;
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