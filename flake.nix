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
                                    champion ? null ,
                                    environment ? x : [ ] ,
                                    extensions ? [ ] ,
                                    name ,
                                    script ,
                                    tests ? null
                                } :
                                    let
                                        primary =
                                            {
                                                champion =
                                                    if builtins.typeOf champion == "null" then champion
                                                    else if builtins.typeOf champion == "string" then champion
                                                    else builtins.throw "champion is not null, string but ${ builtins.typeOf champion }." ;
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
                                                                                                                candidate =
                                                                                                                    if builtins.typeOf primary.champion == "null" then shell-script "candidate"
                                                                                                                    else pkgs.writeShellScriptBin "candidate" primary.champion ;
                                                                                                                constructors =
                                                                                                                    builtins.concatLists
                                                                                                                        [
                                                                                                                            ( builtins.map ( { index , is-file , ... } : "${ _environment-variable ( if is-file then "TOUCH" else "MKDIR" ) } /build/mounts.${ index }" ) secondary.mounts )
                                                                                                                            [
                                                                                                                                "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/test"
                                                                                                                                "source ${ _environment-variable "MAKE_WRAPPER" }/nix-support/setup-hook"
                                                                                                                                "makeWrapper ${ pkgs.writeShellScript "initial" "initial" } ${ _environment-variable "OUT" }/test/initial --set PATH ${ secondary.initial }/bin"
                                                                                                                                "makeWrapper ${ secondary.test } ${ _environment-variable "OUT" }/test/observe --set PATH ${ candidate }/bin"
                                                                                                                                "exec 203> /build/mounts.lock"
                                                                                                                                "${ _environment-variable "FLOCK" } 203"
                                                                                                                                (
                                                                                                                                    let
                                                                                                                                        user-environment =
                                                                                                                                            pkgs.buildFHSUserEnv
                                                                                                                                                {
                                                                                                                                                    extraBwrapArgs = builtins.map ( { index , name , ... } : "--bind /build/mounts.${ index } ${ name }2" ) secondary.mounts ;
                                                                                                                                                    name = "initial" ;
                                                                                                                                                    runScript = "${ _environment-variable "OUT" }/test/initial" ;
                                                                                                                                                } ;
                                                                                                                                        in "${ user-environment }/bin/initial > ${ _environment-variable "OUT" }/test/standard-output 2> ${ _environment-variable "OUT" }/test/standard-error"
                                                                                                                                )
                                                                                                                                "${ _environment-variable "FLOCK" } -u 203"
                                                                                                                            ]
                                                                                                                            [
                                                                                                                                "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/observed"
                                                                                                                                "${ _environment-variable "FLOCK" } 203"
                                                                                                                                (
                                                                                                                                    let
                                                                                                                                        user-environment =
                                                                                                                                            pkgs.buildFHSUserEnv
                                                                                                                                                {
                                                                                                                                                    extraBwrapArgs = builtins.map ( { index , name , ... } : "--bind /build/mounts.${ index } ${ name }" ) secondary.mounts ;
                                                                                                                                                    name = "observe" ;
                                                                                                                                                    runScript = "${ _environment-variable "OUT" }/test/observe" ;
                                                                                                                                                } ;
                                                                                                                                        in "${ user-environment }/bin/observe > ${ _environment-variable "OUT" }/observed/standard-output 2> ${ _environment-variable "OUT" }/observed/standard-error"
                                                                                                                                )
                                                                                                                                "${ _environment-variable "FLOCK" } -u 203"
                                                                                                                                "${ _environment-variable "ECHO" } ${ _environment-variable "?" } > ${ _environment-variable "OUT" }/observed/status"
                                                                                                                            ]
                                                                                                                            (
                                                                                                                                let
                                                                                                                                    mapper =
                                                                                                                                        { index , name , uuid , ... } :
                                                                                                                                            "${ _environment-variable "VACUUM" } /build/mounts.${ index } ${ _environment-variable "OUT" }/observed/mounts.${ index } ${ name } ${ uuid }" ;
                                                                                                                                    in builtins.map mapper secondary.mounts
                                                                                                                            )
                                                                                                                            [
                                                                                                                                "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/expected"
                                                                                                                                "${ _environment-variable "LN" } --symbolic ${ secondary.standard-output } ${ _environment-variable "OUT" }/expected/standard-output"
                                                                                                                                "${ _environment-variable "LN" } --symbolic ${ secondary.standard-error } ${ _environment-variable "OUT" }/expected/standard-error"
                                                                                                                                "${ _environment-variable "ECHO" } ${ secondary.status } > ${ _environment-variable "OUT" }/expected/status"
                                                                                                                            ]
                                                                                                                            (
                                                                                                                                let
                                                                                                                                    mapper =
                                                                                                                                        { expected , index , ... } :
                                                                                                                                            "${ _environment-variable "CP" } --recursive ${ expected } ${ _environment-variable "OUT" }/expected/mounts.${ index }" ;
                                                                                                                                    in builtins.map mapper secondary.mounts
                                                                                                                            )
                                                                                                                        ] ;
                                                                                                                vacuum =
                                                                                                                    pkgs.stdenv.mkDerivation
                                                                                                                        {
                                                                                                                            installPhase =
                                                                                                                                ''
                                                                                                                                    makeWrapper ${ pkgs.writeShellScript "vacuum" ( builtins.readFile ( self + "/vacuum.sh" ) ) } $out --set CAT ${ pkgs.coreutils }/bin/cat --set CHMOD ${ pkgs.coreutils }/bin/chmod --set CUT ${ pkgs.coreutils }/bin/cut --set ECHO ${ pkgs.coreutils }/bin/echo --set FIND ${ pkgs.findutils }/bin/find --set MKDIR ${ pkgs.coreutils }/bin/mkdir --set SHA512SUM ${ pkgs.coreutils }/bin/sha512sum --set STAT ${ pkgs.coreutils }/bin/stat --set WC ${ pkgs.coreutils }/bin/wc
                                                                                                                                '' ;
                                                                                                                            name = "vacuum" ;
                                                                                                                            nativeBuildInputs = [ pkgs.makeWrapper ] ;
                                                                                                                            src = ./. ;
                                                                                                                        } ;
                                                                                                                in
                                                                                                                ''
                                                                                                                    ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                                                        ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                                                                        makeWrapper ${ pkgs.writeShellScript "constructors" ( builtins.concatStringsSep " &&\n\t" constructors ) } $out/bin/constructors --set CHMOD ${ pkgs.coreutils }/bin/chmod --set CP ${ pkgs.coreutils }/bin/cp --set ECHO ${ pkgs.coreutils }/bin/echo --set FLOCK ${ pkgs.flock }/bin/flock --set LN ${ pkgs.coreutils }/bin/ln --set MAKE_WRAPPER ${ pkgs.makeWrapper } --set MKDIR ${ pkgs.coreutils }/bin/mkdir --set MV ${ pkgs.coreutils }/bin/mv --set OUT $out --set TOUCH ${ pkgs.coreutils }/bin/touch --set VACUUM ${ vacuum } &&
                                                                                                                        $out/bin/constructors &&
                                                                                                                        if ${ pkgs.diffutils }/bin/diff --recursive $out/expected $out/observed > $out/difference
                                                                                                                        then
                                                                                                                            ${ pkgs.coreutils }/bin/touch $out/SUCCESS
                                                                                                                        else
                                                                                                                            ${ pkgs.coreutils }/bin/touch $out/FAILURE
                                                                                                                        fi
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
                                                                                                            initial ? "initial" ,
                                                                                                            test ? "candidate"
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
                                                                                                                                                            name : { expected , is-file ? true , uuid ? "" } :
                                                                                                                                                                {
                                                                                                                                                                    expected =
                                                                                                                                                                        if builtins.typeOf expected == "string" then
                                                                                                                                                                            if builtins.pathExists expected then expected
                                                                                                                                                                            else builtins.throw "there is no path for expected ${ expected }."
                                                                                                                                                                        else builtins.throw "expected is not string but ${ builtins.typeOf expected }." ;
                                                                                                                                                                    is-file =
                                                                                                                                                                        if builtins.typeOf is-file == "bool" then is-file
                                                                                                                                                                        else builtins.throw "is-file is not bool but ${ builtins.typeOf is-file }." ;
                                                                                                                                                                    name = name ;
                                                                                                                                                                    uuid =
                                                                                                                                                                        if builtins.typeOf uuid == "string" then builtins.hashString "sha512" uuid
                                                                                                                                                                        else builtins.throw "uuid is not string but ${ builtins.typeOf uuid }." ;
                                                                                                                                                                } ;
                                                                                                                                                        in builtins.mapAttrs mapper mounts ;
                                                                                                                                                in builtins.attrValues set ;
                                                                                                                                        in
                                                                                                                                            {
                                                                                                                                                index = builtins.toString index ;
                                                                                                                                                is-file = elem.is-file ;
                                                                                                                                                expected = elem.expected ;
                                                                                                                                                name = elem.name ;
                                                                                                                                                uuid = elem.uuid ;
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
                                                                                                                initial =
                                                                                                                    if builtins.typeOf initial == "string" then pkgs.writeShellScriptBin "initial" initial
                                                                                                                    else if builtins.typeOf initial == "list" then
                                                                                                                        let
                                                                                                                            mapper = value : if builtins.typeOf value == "string" then value else builtins.throw "initial is not string but ${ builtins.typeOf value }." ;
                                                                                                                            in pkgs.writeShellScriptBin "initial" ( builtins.concatStringsSep " &&\n\t" ( builtins.map mapper initial ) )
                                                                                                                    else builtins.throw "initial is not string but ${ builtins.typeOf initial }." ;
                                                                                                                test =
                                                                                                                    if builtins.typeOf test == "string" then pkgs.writeShellScript "test" test
                                                                                                                    else if builtins.typeOf test == "list" then
                                                                                                                        let
                                                                                                                            mapper = value : if builtins.typeOf value == "string" then value else builtins.throw "test is not string but ${ builtins.typeOf value }." ;
                                                                                                                            in pkgs.writeShellScript "test" ( builtins.concatStringsSep " &&\n\t" ( builtins.map mapper test ) )
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
                                                                                $out/bin/constructors &&
                                                                                ALL=$( ${ pkgs.findutils }/bin/find $out/links -mindepth 1 -type l | ${ pkgs.coreutils }/bin/wc --lines ) &&
                                                                                SUCCESS=$( ${ pkgs.findutils }/bin/find $out/links -mindepth 1 -type l -exec ${ pkgs.coreutils }/bin/readlink {} \; | ${ pkgs.findutils }/bin/find $( ${ pkgs.coreutils }/bin/tee ) -mindepth 1 -maxdepth 1 -type f -name SUCCESS | ${ pkgs.coreutils }/bin/wc --lines ) &&
                                                                                FAILURE=$( ${ pkgs.findutils }/bin/find $out/links -mindepth 1 -type l -exec ${ pkgs.coreutils }/bin/readlink {} \; | ${ pkgs.findutils }/bin/find $( ${ pkgs.coreutils }/bin/tee ) -mindepth 1 -maxdepth 1 -type f -name FAILURE | ${ pkgs.coreutils }/bin/wc --lines ) &&
                                                                                if [ ${ _environment-variable "ALL" } == ${ _environment-variable "SUCCESS" } ] && [ ${ _environment-variable "FAILURE" } == 0 ]
                                                                                then
                                                                                    ${ pkgs.coreutils }/bin/echo ${ _environment-variable "SUCCESS" } > $out/SUCCESS
                                                                                elif [ ${ _environment-variable "ALL" } == $(( ${ _environment-variable "SUCESS" } + ${ _environment-variable "FAILURE" } )) ]
                                                                                then
                                                                                    ${ pkgs.coreutils }/bin/echo ${ _environment-variable "FAILURE" } > $out/FAILURE
                                                                                else
                                                                                    ${ pkgs.coreutils }/bin/echo "${ builtins.concatStringsSep ";" ( builtins.map _environment-variable [ "ALL" "SUCCESS" "FAILURE" ] ) }" => $out/FAILURE
                                                                                fi
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
                                                                            script = self + "/foobar.sh" ;
                                                                            tests =
                                                                                {
                                                                                    file =
                                                                                        ignore :
                                                                                            {
                                                                                                mounts =
                                                                                                    {
                                                                                                        "/singleton" =
                                                                                                            {
                                                                                                                expected = self + "/expected/mounts/singleton" ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                standard-error = self + "/expected/standard-error" ;
                                                                                                standard-output = self + "/expected/standard-output" ;
                                                                                                status = 0 ;
                                                                                                initial =
                                                                                                    [
                                                                                                        "echo hi > /singleton"
                                                                                                    ] ;
                                                                                                test =
                                                                                                    [
                                                                                                        "candidate 2a6273b589f1a8b3ee9e5ad7fc51941863a0b5a8ed1eebe444937292110823579f4b9eb6c72d096012d4cf393335d7e8780ec7ec5d02579aabe050f22ebe2201"
                                                                                                    ] ;
                                                                                            } ;
                                                                                } ;
                                                                        } ;
                                                                in
                                                                    ''
                                                                        ${ pkgs.coreutils }/bin/touch $out &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ shell-script.shell-script } &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ shell-script.tests } &&
                                                                            if [ -f ${ shell-script.tests }/SUCCESS ]
                                                                            then
                                                                                exit 70
                                                                            elif [ -f ${ shell-script.tests }/FAILURE ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo "There was a predicted failure in ${ shell-script.tests }" >&2 &&
                                                                                    exit 63
                                                                            else
                                                                                ${ pkgs.coreutils }/bin/echo "There was an unpredicted failure in ${ shell-script.tests }" >&2 &&
                                                                                    exit 62
                                                                            fi
                                                                    '' ;
                                                        name = "foobar" ;
                                                        src = ./. ;
                                                    } ;
                                        } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}