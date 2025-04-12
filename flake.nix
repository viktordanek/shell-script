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
                            _environment-variable = builtins.getAttr system environment-variable.lib ;
                            lib =
                                {
                                    extensions ? [ ] ,
                                    mounts ? { } ,
                                    name ,
                                    profile ? null ,
                                    script ,
                                    tests ? null ,
                                    over-initialized-target-error-code ? 66 ,
                                    over-initialized-target-error-message ? "Over Initizialized Target" ,
                                    uninitialized-target-error-code ? 67 ,
                                    uninitialized-target-error-message ? "Uninitizialized Target"
                                } :
                                    let
                                        primary =
                                            {
                                                extensions =
                                                    if builtins.typeOf extensions == "set" then
                                                        builtins.mapAttrs ( name : value : if builtins.typeOf value == "lambda" then value else builtins.throw "extension is not lambda but ${ builtins.typeOf value }." ) extensions
                                                    else builtins.throw "extensions is not set but ${ builtins.typeOf extensions }." ;
                                                mounts =
                                                    if builtins.typeOf mounts == "set" then
                                                        let
                                                            mapper =
                                                                name : { host-path ? _environment-variable "TMP_DIR" , is-read-only ? true } :
                                                                    {
                                                                        host-path =
                                                                            if builtins.typeOf host-path == "string" then host-path
                                                                            else builtins.throw "host-path is not string but ${ builtins.typeOf host-path }." ;
                                                                        is-read-only =
                                                                            if builtins.typeOf is-read-only == "bool" then is-read-only
                                                                            else builtins.throw "is-read-only is not bool but ${ builtins.typeOf is-read-only }." ;
                                                                        sandbox = name ;
                                                                    } ;
                                                            in builtins.mapAttrs mapper mounts
                                                    else builtins.throw "mounts is not set but ${ builtins.typeOf mounts }." ;
                                                name =
                                                    if builtins.typeOf name == "string" then
                                                        if pkgs.lib.strings.match "^[a-zA-Z_][a-zA-Z0-9_-]*$" name != null then name
                                                        else builtins.throw "the name (${ name }) is not suitable for a bash script."
                                                    else builtins.throw "name is not string but ${ builtins.typeOf name }." ;
                                                profile =
                                                    if builtins.typeOf profile == "lambda" then
                                                        let
                                                            value = profile primary.extensions ;
                                                            in
                                                                if builtins.typeOf value == "list" then
                                                                    let
                                                                        list = value ;
                                                                        mapper = value : if builtins.typeOf value == "string" then value else builtins.throw "profile is not string but ${ builtins.typeOf value }." ;
                                                                        in builtins.concatStringsSep " &&\n\t" ( builtins.map mapper list )
                                                                else if builtins.typeOf value == "string" then value
                                                                else builtins.throw "profile is not list, string but ${ builtins.typeOf value }."
                                                    else if builtins.typeOf profile == "null" then ""
                                                    else builtins.throw "profile is not lambda, null but ${ builtins.typeOf profile }." ;
                                                script =
                                                    if builtins.typeOf script == "string" then
                                                        if builtins.match "^/.*" script != null then
                                                            if builtins.pathExists script then pkgs.writeShellScript "script" ( builtins.readFile script )
                                                            else builtins.throw "script is an absolute path but there does not exist a path for ${ script }."
                                                        else pkgs.writeShellScript "script" script
                                                    else builtins.throw "script is not string but ${ builtins.typeOf script }." ;
                                                tests =
                                                    if builtins.typeOf tests == "null" then tests
                                                    else if builtins.typeOf tests == "list" then tests
                                                    else if builtins.typeOf tests == "set" then tests
                                                    else builtins.throw "tests is not null, list, set but ${ builtins.typeOf tests }." ;
                                                over-initialized-target-error-code =
                                                    if builtins.typeOf over-initialized-target-error-code == "int" then builtins.toString over-initialized-target-error-code
                                                    else builtins.throw "over-initialized-target-error-code is not int but ${ builtins.typeOf over-initialized-target-error-code }." ;
                                                over-initialized-target-error-message =
                                                    if builtins.typeOf over-initialized-target-error-message == "string" then over-initialized-target-error-message
                                                    else builtins.throw "over-initialized-target-error-message is not string but ${ builtins.typeOf over-initialized-target-error-message }." ;
                                                uninitialized-target-error-code =
                                                    if builtins.typeOf uninitialized-target-error-code == "int" then builtins.toString uninitialized-target-error-code
                                                    else builtins.throw "uninitialized-target-error-code is not init but ${ builtins.typeOf uninitialized-target-error-code }." ;
                                                uninitialized-target-error-message =
                                                    if builtins.typeOf uninitialized-target-error-message == "string" then uninitialized-target-error-message
                                                    else builtins.throw "uninitialized-target-error-message is not string but ${ builtins.typeOf uninitialized-target-error-message }." ;
                                            } ;
                                        shell-script =
                                            { name ? primary.name , mounts ? primary.mounts , profile ? primary.profile } :
                                                pkgs.buildFHSUserEnv
                                                    {
                                                        extraBwrapArgs = builtins.attrValues ( builtins.mapAttrs ( name : { host-path , is-read-only , ... } : "${ if is-read-only then "--ro-bind" else "--bind" } ${ host-path } ${ name }" ) mounts ) ;
                                                        name = name ;
                                                        profile = profile ;
                                                        runScript = primary.script ;
                                                    } ;
                                                tests_ =
                                                    pkgs.stdenv.mkDerivation
                                                        {
                                                            installPhase =
                                                                let
                                                                    _visitor = builtins.getAttr system visitor.lib ;
                                                                    all =
                                                                        _visitor
                                                                            {
                                                                                lambda = path : value : 1 ;
                                                                                null = path : value : 0 ;
                                                                            }
                                                                            {
                                                                                list = path : list : builtins.foldl' ( previous : current : previous + current ) 0 list ;
                                                                                set = path : set : builtins.foldl' ( previous : current : previous + current ) 0 ( builtins.attrValues set ) ;
                                                                            }
                                                                            tests ;
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
                                                                                                                    builtins.concatStringsSep
                                                                                                                        " &&\n\t"
                                                                                                                            (
                                                                                                                                builtins.concatLists
                                                                                                                                    [
                                                                                                                                        [
                                                                                                                                            "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/expected"
                                                                                                                                            "${ _environment-variable "CAT" } ${ secondary.standard-output } > ${ _environment-variable "OUT" }/expected/standard-output"
                                                                                                                                            "${ _environment-variable "CAT" } ${ secondary.standard-error } > ${ _environment-variable "OUT" }/expected/standard-error"
                                                                                                                                            "${ _environment-variable "ECHO" } ${ secondary.status } > ${ _environment-variable "OUT" }/expected/status"
                                                                                                                                            "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/expected/mounts"
                                                                                                                                        ]
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { expected , ... } : "${ _environment-variable "CP" } --recursive ${ expected } ${ _environment-variable "OUT" }/expected/mounts/${ builtins.hashString "sha512" name }" ) secondary.mounts ) )
                                                                                                                                        [
                                                                                                                                            "source ${ _environment-variable "MAKE_WRAPPER" }/nix-support/setup-hook"
                                                                                                                                        ]
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { initial , ... } : "makeWrapper ${ pkgs.writeShellScript "initial" initial } ${ _environment-variable "OUT" }/bin/${ builtins.hashString "sha512" name }.wrapped.sh --set PATH ${ pkgs.coreutils }/bin" ) secondary.mounts ) )
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { initial , ... } : "makeWrapper ${ pkgs.writeShellScript "initial" ( builtins.readFile ( self + "/initial.sh" ) ) } ${ _environment-variable "OUT" }/bin/${ builtins.hashString "sha512" name }.guarded.sh --set ECHO ${ _environment-variable "ECHO" } --set INITIAL ${ _environment-variable "OUT" }/bin/${ builtins.hashString "sha512" name }.wrapped.sh" ) secondary.mounts ) )
                                                                                                                                        (
                                                                                                                                            let
                                                                                                                                                mapper =
                                                                                                                                                    name : { ... } :
                                                                                                                                                        let
                                                                                                                                                            user-environment =
                                                                                                                                                                pkgs.buildFHSUserEnv
                                                                                                                                                                    {
                                                                                                                                                                        extraBwrapArgs = [ "--bind /mount/mounts/${ builtins.hashString "sha512" name } /mount" ] ;
                                                                                                                                                                        name = "initial" ;
                                                                                                                                                                        runScript = "${ _environment-variable "OUT" }/bin/${ builtins.hashString "sha512" name }.guarded.sh" ;
                                                                                                                                                                    } ;
                                                                                                                                                            in "${ _environment-variable "LN" } --symbolic ${ user-environment }/bin/initial ${ _environment-variable "OUT" }/bin/${ builtins.hashString "sha512" name }.shelled.sh" ;
                                                                                                                                                in builtins.attrValues ( builtins.mapAttrs mapper secondary.mounts )
                                                                                                                                        )
                                                                                                                                        [
                                                                                                                                            "makeWrapper ${ pkgs.writeShellScript "observe" observe } ${ _environment-variable "OUT" }/bin/observe.wrapped.sh --set CAT ${ _environment-variable "CAT" } --set CHMOD ${ _environment-variable "CHMOD" } --set CUT ${ _environment-variable "CUT" } --set CP ${ _environment-variable "CP" } --set DIFF ${ _environment-variable "DIFF" } --set ECHO ${ _environment-variable "ECHO" } --set MKDIR ${ _environment-variable "MKDIR" } --set OUT ${ _environment-variable "OUT" } --set SHA512SUM ${ _environment-variable "SHA512SUM" } --set STAT ${ _environment-variable "STAT" }"
                                                                                                                                            (
                                                                                                                                                let
                                                                                                                                                    user-environment =
                                                                                                                                                        pkgs.buildFHSUserEnv
                                                                                                                                                            {
                                                                                                                                                                extraBwrapArgs = [ "--bind ${ _environment-variable "WORK" } /mount" ] ;
                                                                                                                                                                name = "observe" ;
                                                                                                                                                                runScript = "${ _environment-variable "OUT" }/bin/observe.wrapped.sh" ;
                                                                                                                                                            } ;
                                                                                                                                                    in "${ _environment-variable "LN" } --symbolic ${ user-environment }/bin/observe ${ _environment-variable "OUT" }/bin/observe.shelled.sh"
                                                                                                                                            )
                                                                                                                                        ]
                                                                                                                                        [
                                                                                                                                            (
                                                                                                                                                let
                                                                                                                                                    mapper = name : { is-read-only , ... } : { host-path = "/mount/mounts/${ builtins.hashString "sha512" name }/target" ; is-read-only = is-read-only ; } ;
                                                                                                                                                in "makeWrapper ${ secondary.test } ${ _environment-variable "OUT" }/bin/test.wrapped.sh --set OUT ${ _environment-variable "OUT" } --set PATH ${ pkgs.coreutils }/bin:${ shell-script { name = "candidate" ; mounts = builtins.mapAttrs mapper primary.mounts ; } }/bin --set WORK ${ _environment-variable "WORK" }"
                                                                                                                                            )
                                                                                                                                        ]
                                                                                                                                        (
                                                                                                                                            if secondary.delayed then
                                                                                                                                                [
                                                                                                                                                    "${ _environment-variable "TOUCH" } ${ _environment-variable "OUT" }/DELAYED"
                                                                                                                                                ]
                                                                                                                                            else
                                                                                                                                                [
                                                                                                                                                    "export WORK=/build/work"
                                                                                                                                                    "${ _environment-variable "MKDIR" } ${ _environment-variable "WORK" }"
                                                                                                                                                    "${ _environment-variable "OUT" }/bin/observe.shelled.sh"
                                                                                                                                                    "${ _environment-variable "CP" } --recursive ${ _environment-variable "WORK" } ${ _environment-variable "OUT" }"
                                                                                                                                                    "if [ -e ${ _environment-variable "OUT" }/work/SUCCESS ] ; then ${ _environment-variable "TOUCH" } ${ _environment-variable "OUT" }/SUCCESS ; elif [ -e ${ _environment-variable "OUT" }/work/FAILURE ] ; then ${ _environment-variable "TOUCH" } ${ _environment-variable "OUT" }/FAILURE ; else ${ _environment-variable "TOUCH" } ${ _environment-variable "OUT" }/ERROR ; fi"
                                                                                                                                                ]
                                                                                                                                        )
                                                                                                                                    ]
                                                                                                                            ) ;
                                                                                                                observe =
                                                                                                                    builtins.concatStringsSep
                                                                                                                        " &&\n\t"
                                                                                                                        (
                                                                                                                            builtins.concatLists
                                                                                                                                [
                                                                                                                                    [
                                                                                                                                        "${ _environment-variable "MKDIR" } /mount/mounts"
                                                                                                                                    ]
                                                                                                                                    ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "${ _environment-variable "MKDIR" } /mount/mounts/${ builtins.hashString "sha512" name }" ) secondary.mounts ) )
                                                                                                                                    ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "${ _environment-variable "OUT" }/bin/${ builtins.hashString "sha512" name }.shelled.sh" ) secondary.mounts ) )
                                                                                                                                    [
                                                                                                                                        "${ _environment-variable "MKDIR" } /mount/initial"
                                                                                                                                    ]
                                                                                                                                    ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "${ _environment-variable "CP" } --recursive /mount/mounts/${ builtins.hashString "sha512" name } /mount/initial/${ builtins.hashString "sha512" name }" ) secondary.mounts ) )
                                                                                                                                    [
                                                                                                                                        "${ _environment-variable "MKDIR" } /mount/observed"
                                                                                                                                        "if ${ _environment-variable "OUT" }/bin/test.wrapped.sh > /mount/observed/standard-output 2> /mount/observed/standard-error ; then ${ _environment-variable "ECHO" } ${ _environment-variable "?" } > /mount/observed/status ; else ${ _environment-variable "ECHO" } ${ _environment-variable "?" } > /mount/observed/status ; fi"
                                                                                                                                        "${ _environment-variable "MKDIR" } /mount/observed/mounts"
                                                                                                                                    ]
                                                                                                                                    ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "${ _environment-variable "MKDIR" } /mount/observed/mounts/${ builtins.hashString "sha512" name }" ) secondary.mounts ) )
                                                                                                                                    ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "${ _environment-variable "FIND" } /mount/mounts/${ builtins.hashString "sha512" name }/target -mindepth 0 | while read FILE ; do UUID=$( ${ _environment-variable "ECHO" } ${ _environment-variable "FILE#/mount/mounts/${ builtins.hashString "sha512" name }/target" } | ${ _environment-variable "SHA512SUM" } | ${ _environment-variable "CUT" } --bytes -128 ) && ${ _environment-variable "ECHO" } ${ name }-${ _environment-variable "FILE#/mount/mounts/${ builtins.hashString "sha512" name }/target" } > /mount/observed/mounts/${ builtins.hashString "sha512" name }/${ _environment-variable "UUID" }.key && ${ _environment-variable "STAT" } --format %A ${ _environment-variable "FILE" } > /mount/observed/mounts/${ builtins.hashString "sha512" name }/${ _environment-variable "UUID" }.stat && if [ -f ${ _environment-variable "FILE" } ] ; then ${ _environment-variable "CAT" } ${ _environment-variable "FILE" } > /mount/observed/mounts/${ builtins.hashString "sha512" name }/${ _environment-variable "UUID" }.cat ; fi ; done" ) secondary.mounts ) )
                                                                                                                                    [
                                                                                                                                        "${ _environment-variable "CHMOD" } -R 0777 /mount/observed/*"
                                                                                                                                        "if ${ _environment-variable "DIFF" } --recursive ${ _environment-variable "OUT" }/expected /mount/observed > /mount/DIFF ; then ${ _environment-variable "TOUCH" } /mount/SUCCESS ; else ${ _environment-variable "TOUCH" } /mount/FAILURE ; fi"
                                                                                                                                    ]
                                                                                                                                ]
                                                                                                                        ) ;
                                                                                                                in
                                                                                                                    ''
                                                                                                                        ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                                                            ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                                                                            ${ pkgs.coreutils }/bin/ln --symbolic ${ pkgs.writeShellScript "constructors" constructors } $out/bin/constructors.sh &&
                                                                                                                            makeWrapper $out/bin/constructors.sh $out/bin/constructors --set CAT ${ pkgs.coreutils }/bin/cat --set CHMOD ${ pkgs.coreutils }/bin/chmod --set CP ${ pkgs.coreutils }/bin/cp --set CUT ${ pkgs.coreutils }/bin/cut --set DIFF ${ pkgs.diffutils }/bin/diff --set ECHO ${ pkgs.coreutils }/bin/echo --set FIND ${ pkgs.findutils }/bin/find --set LN ${ pkgs.coreutils }/bin/ln --set MKDIR ${ pkgs.coreutils }/bin/mkdir --set MAKE_WRAPPER ${ pkgs.makeWrapper } --set OUT $out --set RM ${ pkgs.coreutils }/bin/rm --set SHA512SUM ${ pkgs.coreutils }/bin/sha512sum --set STAT ${ pkgs.coreutils }/bin/stat --set TOUCH ${ pkgs.coreutils }/bin/touch --set WC ${ pkgs.coreutils }/bin/wc &&
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
                                                                                                            delayed ? false ,
                                                                                                            mounts ? { } ,
                                                                                                            profile ? null ,
                                                                                                            standard-error ? "" ,
                                                                                                            standard-output ? "" ,
                                                                                                            status ? 0 ,
                                                                                                            initial ? "initial" ,
                                                                                                            test ? "candidate"
                                                                                                        } :
                                                                                                            {
                                                                                                                delayed =
                                                                                                                    if builtins.typeOf delayed == "bool" then delayed
                                                                                                                    else builtins.throw "delayed is not bool but ${ builtins.typeOf delayed }." ;
                                                                                                                mounts =
                                                                                                                    if builtins.typeOf mounts == "set" then
                                                                                                                        if builtins.sort ( a : b : a < b ) ( builtins.attrNames primary.mounts ) == builtins.sort ( a : b : a < b ) ( builtins.attrNames mounts )
                                                                                                                        then
                                                                                                                            let
                                                                                                                                mapper =
                                                                                                                                    name : { expected , initial } :
                                                                                                                                        {
                                                                                                                                            expected =
                                                                                                                                                if builtins.typeOf expected == "string" then
                                                                                                                                                    if builtins.pathExists expected then expected
                                                                                                                                                    else builtins.throw "path does not exist for expected ${ expected }."
                                                                                                                                                else builtins.throw "expected is not string but ${ builtins.typeOf expected }." ;
                                                                                                                                            expected-path = "${ _environment-variable "OUT" }/expected/${ builtins.hashString "sha512" name }" ;
                                                                                                                                            host-path = "/build/mount.${ builtins.hashString "sha512" name }" ;
                                                                                                                                            initial =
                                                                                                                                                if builtins.typeOf initial == "list" then pkgs.writeShellScript "initial" ( builtins.concatStringsSep " &&\n\t" ( builtins.map ( value : if builtins.typeOf value == "string" then value else builtins.throw "initial is not string but ${ builtins.typeOf value }." ) initial ) )
                                                                                                                                                else builtins.throw "initial is not list, string but ${ builtins.typeOf initial }." ;
                                                                                                                                            is-read-only = builtins.getAttr "is-read-only" ( builtins.getAttr name primary.mounts ) ;
                                                                                                                                            observed-path = "${ _environment-variable "OUT" }/observed/${ builtins.hashString "sha512" name }" ;
                                                                                                                                            test-path = "${ _environment-variable "OUT" }/test/initial.${ builtins.hashString "sha512" name }" ;
                                                                                                                                            temporary-path = "${ _environment-variable "TEMP" }/mounts/${ builtins.hashString "sha512" name }" ;
                                                                                                                                        } ;
                                                                                                                                in builtins.mapAttrs mapper mounts
                                                                                                                        else builtins.throw "the testing mounts (${ builtins.toJSON ( builtins.attrNames mounts ) }) does not have the same sandbox attributes as the primary mounts (${ builtins.toJSON ( builtins.attrNames primary.mounts ) })."
                                                                                                                    else builtins.throw "mounts is not set but ${ builtins.typeOf mounts }." ;
                                                                                                                profile =
                                                                                                                    if builtins.typeOf profile == "lambda" then
                                                                                                                        let
                                                                                                                            value = profile primary.extensions ;
                                                                                                                            in
                                                                                                                                if builtins.typeOf value == "list"
                                                                                                                                then
                                                                                                                                    let
                                                                                                                                        list = value ;
                                                                                                                                        mapper = value : if builtins.typeOf value == "string" then value else builtins.throw "profile is not string but ${ builtins.typeOf value }." ;
                                                                                                                                        in builtins.concatStringsSep " &&\n\t" ( builtins.map mapper list )
                                                                                                                                else if builtins.typeOf value == "string" then value
                                                                                                                                else builtins.throw "profile is not list, string but ${ builtins.typeOf value }."
                                                                                                                    else if builtins.typeOf profile == "null" then primary.profile
                                                                                                                    else builtins.throw "profile is not lambda but ${ builtins.typeOf profile }." ;
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
                                                                                                                    if builtins.typeOf test == "string" then test
                                                                                                                    else if builtins.typeOf test == "list" then
                                                                                                                        let
                                                                                                                            mapper = value : if builtins.typeOf value == "string" then value else builtins.throw "test is not string but ${ builtins.typeOf value }." ;
                                                                                                                            in pkgs.writeShellScript "tests" ( builtins.concatStringsSep " &&\n\t" ( builtins.map mapper test ) )
                                                                                                                    else builtins.throw "test is not string but ${ builtins.typeOf test }." ;
                                                                                                            } ;
                                                                                                in identity ( value null ) ;
                                                                                            in
                                                                                                [
                                                                                                    "${ _environment-variable "MKDIR" } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ ( _environment-variable "OUT" ) "links" ] ( builtins.map builtins.toJSON path ) ] ) }"
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
                                                                                ALL=${ builtins.toString all } &&
                                                                                if [ ! -d $out/links ]
                                                                                then
                                                                                    ${ pkgs.coreutils }/bin/mkdir $out/links
                                                                                fi &&
                                                                                DELAYED=$( ${ pkgs.findutils }/bin/find $out/links -mindepth 1 -type l -exec ${ pkgs.coreutils }/bin/readlink {} \; | ${ pkgs.findutils }/bin/find $( ${ pkgs.coreutils }/bin/tee ) -mindepth 1 -maxdepth 1 -type f -name DELAYED | ${ pkgs.coreutils }/bin/wc --lines ) &&
                                                                                SUCCESS=$( ${ pkgs.findutils }/bin/find $out/links -mindepth 1 -type l -exec ${ pkgs.coreutils }/bin/readlink {} \; | ${ pkgs.findutils }/bin/find $( ${ pkgs.coreutils }/bin/tee ) -mindepth 1 -maxdepth 1 -type f -name SUCCESS | ${ pkgs.coreutils }/bin/wc --lines ) &&
                                                                                FAILURE=$( ${ pkgs.findutils }/bin/find $out/links -mindepth 1 -type l -exec ${ pkgs.coreutils }/bin/readlink {} \; | ${ pkgs.findutils }/bin/find $( ${ pkgs.coreutils }/bin/tee ) -mindepth 1 -maxdepth 1 -type f -name FAILURE | ${ pkgs.coreutils }/bin/wc --lines ) &&
                                                                                if [ ${ _environment-variable "ALL" } == ${ _environment-variable "SUCCESS" } ] && [ ${ _environment-variable "FAILURE" } == 0 ]
                                                                                then
                                                                                    ${ pkgs.coreutils }/bin/touch $out/SUCCESS
                                                                                elif [ ${ _environment-variable "ALL" } == $(( ${ _environment-variable "SUCCESS" } + ${ _environment-variable "DELAYED" } )) ]
                                                                                then
                                                                                    ${ pkgs.findutils }/bin/find $out/links -mindepth 1 -type l -exec ${ pkgs.coreutils }/bin/readlink {} \; | ${ pkgs.findutils }/bin/find $( ${ pkgs.coreutils }/bin/tee ) -mindepth 1 -maxdepth 1 -type f -name DELAYED | ${ pkgs.coreutils }/bin/dirname $( ${ pkgs.coreutils }/bin/tee ) > $out/DELAYED
                                                                                elif [ ${ _environment-variable "ALL" } == $(( ${ _environment-variable "SUCCESS" } + ${ _environment-variable "DELAYED" } + ${ _environment-variable "FAILURE" } )) ]
                                                                                then
                                                                                    ${ pkgs.findutils }/bin/find $out/links -mindepth 1 -type l -exec ${ pkgs.coreutils }/bin/readlink {} \; | ${ pkgs.findutils }/bin/find $( ${ pkgs.coreutils }/bin/tee ) -mindepth 1 -maxdepth 1 -type f -name FAILURE | ${ pkgs.coreutils }/bin/dirname $( ${ pkgs.coreutils }/bin/tee ) > $out/FAILURE
                                                                                else
                                                                                    ${ pkgs.coreutils }/bin/echo "{ ALL : ${ _environment-variable "ALL" } , DELAYED : ${ _environment-variable "DELAYED" } , SUCCESS : ${ _environment-variable "SUCCESS" } , FAILURE : ${ _environment-variable "FAILURE" } }" > $out/ERROR
                                                                                fi
                                                                        '';
                                                            name = "tests" ;
                                                            nativeBuildInputs = [ pkgs.makeWrapper ] ;
                                                            src = ./. ;
                                                        } ;
                                        in
                                            {
                                                shell-script = "${ shell-script { } }/bin/${ primary.name }" ;
                                                post-tests =
                                                    pkgs.writeShellScript
                                                        "post-tests"
                                                        ''
                                                        '' ;
                                                tests = tests_ ;
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
                                                                foobar =
                                                                    lib
                                                                        {
                                                                            extensions =
                                                                                {
                                                                                    string = name : value : "export ${ name }=${ value }" ;
                                                                                } ;
                                                                            name = "foobar" ;
                                                                            mounts =
                                                                                {
                                                                                    "/singleton" =
                                                                                        {
                                                                                            is-read-only = false ;
                                                                                        } ;
                                                                                } ;
                                                                            profile =
                                                                                { string } :
                                                                                    [
                                                                                        ( string "CAT" "${ pkgs.coreutils }/bin/cat" )
                                                                                        ( string "CUT" "${ pkgs.coreutils }/bin/cut" )
                                                                                        ( string "CHMOD" "${ pkgs.coreutils }/bin/chmod" )
                                                                                        ( string "DIFF" "${ pkgs.diffutils }/bin/diff" )
                                                                                        ( string "ECHO" "${ pkgs.coreutils }/bin/echo" )
                                                                                        ( string "SHA512SUM" "${ pkgs.coreutils }/bin/sha512sum" )
                                                                                    ] ;
                                                                            script = self + "/foobar.sh" ;
                                                                            tests =
                                                                                {
                                                                                    delayed =
                                                                                        ignore :
                                                                                            {
                                                                                                delayed = true ;
                                                                                                mounts =
                                                                                                    {
                                                                                                        "/singleton" =
                                                                                                            {
                                                                                                                expected = self + "/expected/foobar/file/mounts/singleton" ;
                                                                                                                initial =
                                                                                                                    [
                                                                                                                        "echo 0d157cd5708ec01d0b865b8fbef69d7b28713423ec011a86a5278cf566bcbd8e79a2daa996d7b1b8224088711b75fda91bdc1d41d0e53dd7118cfbdec8296044 > /mount/target"
                                                                                                                    ] ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                standard-error = self + "/expected/foobar/file/standard-error" ;
                                                                                                standard-output = self + "/expected/foobar/file/standard-output" ;
                                                                                                status = 168 ;
                                                                                                test =
                                                                                                    [
                                                                                                        "candidate 2a6273b589f1a8b3ee9e5ad7fc51941863a0b5a8ed1eebe444937292110823579f4b9eb6c72d096012d4cf393335d7e8780ec7ec5d02579aabe050f22ebe2201"
                                                                                                    ] ;
                                                                                            } ;
                                                                                    directory =
                                                                                        ignore :
                                                                                            {
                                                                                                mounts =
                                                                                                    {
                                                                                                        "/singleton" =
                                                                                                            {
                                                                                                                expected = self + "/expected/foobar/directory/mounts/singleton" ;
                                                                                                                initial =
                                                                                                                    [
                                                                                                                        "mkdir /mount/target"
                                                                                                                    ] ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                standard-error = self + "/expected/foobar/directory/standard-error" ;
                                                                                                standard-output = self + "/expected/foobar/directory/standard-output" ;
                                                                                                status = 9 ;
                                                                                                test =
                                                                                                    [
                                                                                                        "candidate f30f8072a080c2e76d53e790954f9ac516ee6fdfec424db97021bf267119429247279d2dcdd5a1c18a8c1c8b0282099d1c88ce2471b9d4f00c22663911f1e541"
                                                                                                    ] ;
                                                                                            } ;
                                                                                    file =
                                                                                        ignore :
                                                                                            {
                                                                                                mounts =
                                                                                                    {
                                                                                                        "/singleton" =
                                                                                                            {
                                                                                                                expected = self + "/expected/foobar/file/mounts/singleton" ;
                                                                                                                initial =
                                                                                                                    [
                                                                                                                        "echo 0d157cd5708ec01d0b865b8fbef69d7b28713423ec011a86a5278cf566bcbd8e79a2daa996d7b1b8224088711b75fda91bdc1d41d0e53dd7118cfbdec8296044 > /mount/target"
                                                                                                                    ] ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                standard-error = self + "/expected/foobar/file/standard-error" ;
                                                                                                standard-output = self + "/expected/foobar/file/standard-output" ;
                                                                                                status = 168 ;
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
                                                                            ${ pkgs.coreutils }/bin/echo The script is ${ foobar.shell-script }. &&
                                                                            ${ pkgs.coreutils }/bin/echo The tests are ${ foobar.tests }. &&
                                                                            ${ pkgs.coreutils }/bin/echo The post-tests are ${ foobar.post-tests }. &&
                                                                            if [ -f ${ foobar.tests }/SUCCESS ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo There was success in ${ foobar.tests }. >&2 &&
                                                                                    exit 63
                                                                            elif [ -f ${ foobar.tests }/DELAYED ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo There was delay in ${ foobar.tests }.
                                                                            elif [ -f ${ foobar.tests }/FAILURE ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo There was a predicted failure in ${ foobar.tests } >&2 &&
                                                                                    exit 61
                                                                            else
                                                                                ${ pkgs.coreutils }/bin/echo There was an unpredicted failure in ${ foobar.tests } >&2 &&

                                                                                    exit 60
                                                                            fi
                                                                    '' ;
                                                        name = "foobar" ;
                                                        src = ./. ;
                                                    } ;
                                            simple =
                                                pkgs.stdenv.mkDerivation
                                                    {
                                                        installPhase =
                                                            let
                                                                simple =
                                                                    lib
                                                                        {
                                                                            extensions =
                                                                                {
                                                                                    string = name : value : "export ${ name }=${ builtins.toString value }" ;
                                                                                } ;
                                                                            name = "simple" ;
                                                                            profile =
                                                                                { string } :
                                                                                    [
                                                                                        ( string "ECHO" "${ pkgs.coreutils }/bin/echo" )
                                                                                        ( string "STANDARD_ERROR" "00008455e9b8b7515abcdf5ad30c1bc81abb412e8410b9cfdb90f4e2d47d876a7ffb0a2953fa06cd6a521371182296770b5e12b9b2676cfece23f78370050f93" )
                                                                                        ( string "STANDARD_OUTPUT" "e832ac101647d4cd5bf2229c53f6174b42c68d841d390562de6dad9006d59b9c3ae7e358792de18b405fd28d9276d31e4610a4340a70f949ce6b2caa0ed1e263" )
                                                                                        ( string "STATUS" 102 )
                                                                                    ] ;
                                                                            script =
                                                                                ''
                                                                                    ${ _environment-variable "ECHO" } -en ${ _environment-variable "STANDARD_OUTPUT" } &&
                                                                                        ${ _environment-variable "ECHO" } -en ${ _environment-variable "STANDARD_ERROR" } >&2 &&
                                                                                        exit ${ _environment-variable "STATUS" }
                                                                                '';
                                                                            tests =
                                                                                ignore :
                                                                                    {
                                                                                        standard-error = "00008455e9b8b7515abcdf5ad30c1bc81abb412e8410b9cfdb90f4e2d47d876a7ffb0a2953fa06cd6a521371182296770b5e12b9b2676cfece23f78370050f93" ;
                                                                                        standard-output = "e832ac101647d4cd5bf2229c53f6174b42c68d841d390562de6dad9006d59b9c3ae7e358792de18b405fd28d9276d31e4610a4340a70f949ce6b2caa0ed1e263" ;
                                                                                        status = 102 ;
                                                                                    } ;
                                                                        } ;
                                                                in
                                                                    ''
                                                                        ${ pkgs.coreutils }/bin/touch $out &&
                                                                            ${ pkgs.coreutils }/bin/echo The script is ${ simple.shell-script }. &&
                                                                            ${ pkgs.coreutils }/bin/echo The tests are ${ simple.tests }. &&
                                                                            ${ pkgs.coreutils }/bin/echo The post-tests are ${ simple.post-tests }. &&
                                                                            if [ -f ${ simple.tests }/SUCCESS ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo There was success in ${ simple.tests }.
                                                                            elif [ -f ${ simple.tests }/DELAYED ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo There was delay in ${ simple.tests }. >&2 &&
                                                                                    exit 62
                                                                            elif [ -f ${ simple.tests }/FAILURE ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo There was failure in ${ simple.tests }. >&2 &&
                                                                                    exit 61
                                                                            else
                                                                                ${ pkgs.coreutils }/bin/echo There was error in ${ simple.tests }. >&2 &&
                                                                                    exit 60
                                                                            fi
                                                                    '' ;
                                                        name = "simple" ;
                                                        src = ./. ;
                                                    } ;
                                        } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}