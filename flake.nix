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
                                                        if builtins.pathExists script then pkgs.writeShellScript "script" ( builtins.readFile script )
                                                        else builtins.throw "there is no path for ${ script }."
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
                                        in
                                            {
                                                shell-script = "${ shell-script { } }/bin/${ primary.name }" ;
                                                tests =
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
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { initial-path , ... } : "${ _environment-variable "MKDIR" } ${ initial-path }" ) secondary.mounts ) )
                                                                                                                                        [
                                                                                                                                            "source ${ _environment-variable "MAKE_WRAPPER" }/nix-support/setup-hook"
                                                                                                                                        ]
                                                                                                                                        [
                                                                                                                                            "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/test"
                                                                                                                                        ]
                                                                                                                                        (
                                                                                                                                            let
                                                                                                                                                mapper =
                                                                                                                                                    name : { initial , initial-path , ... } :
                                                                                                                                                        let
                                                                                                                                                            user-environment =
                                                                                                                                                                pkgs.buildFHSUserEnv
                                                                                                                                                                    {
                                                                                                                                                                        extraBwrapArgs = [ "--unshare-all" "--bind ${ initial-path } /mount" ] ;
                                                                                                                                                                        name = "initial" ;
                                                                                                                                                                        runScript = initial ;
                                                                                                                                                                        targetPkgs = pkgs : [ pkgs.coreutils ] ;
                                                                                                                                                                    } ;
                                                                                                                                                            in "if ${ user-environment }/bin/initial > ${ initial-path }/standard-output 2> ${ initial-path }/standard-error ; then ${ _environment-variable "ECHO" } ${ _environment-variable "?" } > ${ initial-path }/status ; else ${ _environment-variable "ECHO" } ${ _environment-variable "?" } > ${ initial-path }/status ; fi" ;
                                                                                                                                                in builtins.attrValues ( builtins.mapAttrs mapper secondary.mounts )
                                                                                                                                        )
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { initial-path , ... } : "if [ ! -e ${ initial-path }/target ] ; then ${ _environment-variable "ECHO" } ${ primary.uninitialized-target-error-message } >&2 && exit ${ primary.uninitialized-target-error-code } ; fi" ) secondary.mounts ) )
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { initial-path , ... } : "if [ $( ${ _environment-variable "FIND" } ${ initial-path } -mindepth 1 -maxdepth 1 | ${ _environment-variable "WC" } --lines ) != 1 ; then ${ _environment-variable "ECHO" } ${ primary.over-initialized-target-error-message } >&2 && exit ${ primary.over-initialized-target-error-code } ; fi" ) secondary.mounts ) )
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { initial-path , host-path , ... } : "${ _environment-variable "CP" } --recursive ${ initial-path }/target ${ host-path }" ) secondary.mounts ) )
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { initial-path , test-path , ... } : "${ _environment-variable "CP" } --recursive ${ initial-path }/target ${ test-path }" ) secondary.mounts ) )
                                                                                                                                        [
                                                                                                                                            "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/observed"
                                                                                                                                            (
                                                                                                                                                let
                                                                                                                                                    user-environment =
                                                                                                                                                        pkgs.buildFHSUserEnv
                                                                                                                                                            {
                                                                                                                                                                name = "observe" ;
                                                                                                                                                                runScript = secondary.test ;
                                                                                                                                                                targetPkgs = pkgs : [ pkgs.coreutils ( shell-script { mounts = secondary.mounts ; name = "candidate" ; profile = secondary.profile ; } ) ] ;
                                                                                                                                                            } ;
                                                                                                                                                    in
                                                                                                                                                        "if ${ user-environment }/bin/observe > ${ _environment-variable "OUT" }/observed/standard-output 2> ${ _environment-variable "OUT" }/observed/standard-error ; then ${ _environment-variable "ECHO" } ${ _environment-variable "?" } > ${ _environment-variable "OUT" }/observed/status ; else ${ _environment-variable "ECHO" } ${ _environment-variable "?" } > ${ _environment-variable "OUT" }/observed/status ; fi"
                                                                                                                                            )
                                                                                                                                        ]
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { host-path , vacuum-path , ... } : "if [ -e ${ host-path } ] ; then ${ _environment-variable "MKDIR" } ${ vacuum-path } && INPUT=${ host-path } OUTPUT=${ vacuum-path } ${ _environment-variable "VACUUM" } ; fi" ) secondary.mounts ) )
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { observed-path , vacuum-path , ... } : "if [ -d ${ vacuum-path } ] ; then ${ _environment-variable "CP" } --recursive ${ vacuum-path } ${ observed-path } ; fi" ) secondary.mounts ) )
                                                                                                                                        [
                                                                                                                                            "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/expected"
                                                                                                                                            "${ _environment-variable "CAT" } ${ secondary.standard-output } > ${ _environment-variable "OUT" }/expected/standard-output"
                                                                                                                                            "${ _environment-variable "CAT" } ${ secondary.standard-error } > ${ _environment-variable "OUT" }/expected/standard-error"
                                                                                                                                            "${ _environment-variable "ECHO" } ${ secondary.status } > ${ _environment-variable "OUT" }/expected/status"
                                                                                                                                        ]
                                                                                                                                        ##FIXME
                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { expected , expected-path , ... } : "${ _environment-variable "CP" } --recursive ${ expected } ${ expected-path }" ) secondary.mounts ) )
                                                                                                                                        [
                                                                                                                                            "if ${ _environment-variable "DIFF" } --recursive ${ _environment-variable "OUT" }/expected ${ _environment-variable "OUT" }/observed > ${ _environment-variable "OUT" }/diff ; then ${ _environment-variable "TOUCH" } ${ _environment-variable "OUT" }/SUCCESS ; else ${ _environment-variable "TOUCH" } ${ _environment-variable "OUT" }/FAILURE ; fi"
                                                                                                                                        ]
                                                                                                                                    ]
                                                                                                                            ) ;
                                                                                                                in
                                                                                                                    ''
                                                                                                                        ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                                                            ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                                                                            ${ pkgs.coreutils }/bin/ln --symbolic ${ pkgs.writeShellScript "constructors" constructors } $out/bin/constructors.sh &&
                                                                                                                            makeWrapper $out/bin/constructors.sh $out/bin/constructors --set CAT ${ pkgs.coreutils }/bin/cat --set CP ${ pkgs.coreutils }/bin/cp --set DIFF ${ pkgs.diffutils }/bin/diff --set ECHO ${ pkgs.coreutils }/bin/echo --set MKDIR ${ pkgs.coreutils }/bin/mkdir --set MAKE_WRAPPER ${ pkgs.makeWrapper } --set OUT $out --set TOUCH ${ pkgs.coreutils }/bin/touch --set VACUUM ${ vacuum.shell-script } &&
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
                                                                                                            profile ? null ,
                                                                                                            standard-error ? "" ,
                                                                                                            standard-output ? "" ,
                                                                                                            status ? 0 ,
                                                                                                            initial ? "initial" ,
                                                                                                            test ? "candidate"
                                                                                                        } :
                                                                                                            {
                                                                                                                mounts =
                                                                                                                    if builtins.typeOf mounts == "set" then
                                                                                                                        if builtins.sort ( a : b : a < b ) ( builtins.attrNames primary.mounts ) == builtins.sort ( a : b : a < b ) ( builtins.attrNames mounts )
                                                                                                                        then
                                                                                                                            let
                                                                                                                                mapper =
                                                                                                                                    name : { expected , initial } :
                                                                                                                                        {
                                                                                                                                            host-path = "/build/mount.${ builtins.hashString "sha512" name }" ;
                                                                                                                                            expected =
                                                                                                                                                if builtins.typeOf expected == "string" then
                                                                                                                                                    if builtins.pathExists expected then expected
                                                                                                                                                    else builtins.throw "path does not exist for expected ${ expected }."
                                                                                                                                                else builtins.throw "expected is not string but ${ builtins.typeOf expected }." ;
                                                                                                                                            expected-path = "${ _environment-variable "OUT" }/expected/${ builtins.hashString "sha512" name }" ;
                                                                                                                                            initial =
                                                                                                                                                if builtins.typeOf initial == "list" then builtins.concatStringsSep " &&\n\t" ( builtins.map ( value : if builtins.typeOf value == "string" then value else builtins.throw "initial is not string but ${ builtins.typeOf value }." ) initial )
                                                                                                                                                else if builtins.typeOf initial == "string" then initial
                                                                                                                                                else builtins.throw "initial is not list, string but ${ builtins.typeOf initial }." ;
                                                                                                                                            initial-path = "/build/initial.${ builtins.hashString "sha512" name }" ;
                                                                                                                                            is-read-only = builtins.getAttr "is-read-only" ( builtins.getAttr name primary.mounts ) ;
                                                                                                                                            observed-path = "${ _environment-variable "OUT" }/observed/${ builtins.hashString "sha512" name }" ;
                                                                                                                                            test-path = "${ _environment-variable "OUT" }/test/initial.${ builtins.hashString "sha512" name }" ;
                                                                                                                                            vacuum-path = "/build/vacuum.${ builtins.hashString "sha512" name }" ;
                                                                                                                                        } ;
                                                                                                                                in builtins.mapAttrs mapper mounts
                                                                                                                        else builtins.throw "the testing mounts does not have the same sandbox attributes as the primary mounts."
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
                                                                                                                                        in builtins.map mapper list
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
                                                                                                                            in builtins.concatStringsSep " &&\n\t" ( builtins.map mapper test )
                                                                                                                    else builtins.throw "test is not string but ${ builtins.typeOf test }." ;
                                                                                                            } ;
                                                                                                in identity ( value null ) ;
                                                                                            in
                                                                                                [
                                                                                                    "${ _environment-variable "MKDIR" } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ ( _environment-variable "OUT" ) "links" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                    "${ _environment-variable "LN" } --symbolic ${ derivation } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ ( _environment-variable "OUT" ) "links" ] ( builtins.map builtins.toJSON path ) [ "${ builtins.baseNameOf derivation }" ] ] ) }"
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
                                                                                SUCCESS=$( ${ pkgs.findutils }/bin/find $out/links -mindepth 1 -type l -exec ${ pkgs.coreutils }/bin/readlink {} \; | ${ pkgs.findutils }/bin/find $( ${ pkgs.coreutils }/bin/tee ) -mindepth 1 -maxdepth 1 -type f -name SUCCESS | ${ pkgs.coreutils }/bin/wc --lines ) &&
                                                                                FAILURE=$( ${ pkgs.findutils }/bin/find $out/links -mindepth 1 -type l -exec ${ pkgs.coreutils }/bin/readlink {} \; | ${ pkgs.findutils }/bin/find $( ${ pkgs.coreutils }/bin/tee ) -mindepth 1 -maxdepth 1 -type f -name FAILURE | ${ pkgs.coreutils }/bin/wc --lines ) &&
                                                                                if [ ${ _environment-variable "ALL" } == ${ _environment-variable "SUCCESS" } ] && [ ${ _environment-variable "FAILURE" } == 0 ]
                                                                                then
                                                                                    ${ pkgs.coreutils }/bin/echo ${ _environment-variable "SUCCESS" } > $out/SUCCESS
                                                                                elif [ ${ _environment-variable "ALL" } == $(( ${ _environment-variable "SUCCESS" } + ${ _environment-variable "FAILURE" } )) ]
                                                                                then
                                                                                    ${ pkgs.coreutils }/bin/echo ${ _environment-variable "FAILURE" } > $out/FAILURE
                                                                                else
                                                                                    ${ pkgs.coreutils }/bin/echo "{ ALL : ${ _environment-variable "ALL" } , SUCCESS : ${ _environment-variable "SUCCESS" } , FAILURE : ${ _environment-variable "FAILURE" } }" > $out/ERROR
                                                                                fi
                                                                        '';
                                                            name = "tests" ;
                                                            nativeBuildInputs = [ pkgs.makeWrapper ] ;
                                                            src = ./. ;
                                                        } ;
                                            } ;
                            pkgs = builtins.import nixpkgs { system = system ; } ;
                            vacuum =
                                lib
                                    {
                                        extensions =
                                            {
                                                string = name : value : "export ${ name }=${ builtins.toString value }" ;
                                            } ;
                                        mounts =
                                            {
                                                input =
                                                    {
                                                        host-path = _environment-variable "INPUT" ;
                                                        is-read-only = true ;
                                                    } ;
                                                output =
                                                    {
                                                        host-path = _environment-variable "OUTPUT" ;
                                                        is-read-only = false ;
                                                    } ;
                                            } ;
                                        name = "vacuum" ;
                                        profile =
                                            { string } :
                                                [
                                                    ( string "CAT" "${ pkgs.coreutils }/bin/cat" )
                                                    ( string "CHMOD" "${ pkgs.coreutils }/bin/chmod" )
                                                    ( string "CUT" "${ pkgs.coreutils }/bin/cut" )
                                                    ( string "ECHO" "${ pkgs.coreutils }/bin/echo" )
                                                    ( string "FIND" "${ pkgs.findutils }/bin/find" )
                                                    ( string "MKDIR" "${ pkgs.coreutils }/bin/mkdir" )
                                                    ( string "SHA512SUM" "${ pkgs.coreutils }/bin/sha512sum" )
                                                    ( string "STAT" "${ pkgs.coreutils }/bin/stat" )
                                                    ( string "UUID" "706fd7726e3d7fd7fbd98a95c3222049fbe419934cbd41dcf324a6a004b69b561b6304d2b4030df318ee1cbd20cd74a1524d1f74116a2b900979ba66ed4eadc8" )
                                                    ( string "WC" "${ pkgs.coreutils }/bin/wc" )
                                                ] ;
                                        script = self + "/vacuum.sh" ;
                                        tests =
                                            ignore :
                                                {
                                                    mounts =
                                                        {
                                                            input =
                                                                {
                                                                    expected = self + "/expected/vacuum/mounts/input" ;
                                                                    initial =
                                                                        [
                                                                            "echo 3275d3d7a12620ea996ca571c341cd66258f413f11796a3a596de316fbd4477b34b1251a10a38044b98e1f757343102f4848e77961aae44e916ef0b2b1c2070c > /mount/target"
                                                                        ] ;
                                                                } ;
                                                            output =
                                                                {
                                                                    expected = self + "/expected/vacuum/mounts/output" ;
                                                                    initial =
                                                                        [
                                                                            "mkdir /mount/target"
                                                                        ] ;
                                                                } ;
                                                        } ;
                                                } ;
                                    } ;
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
                                                                            ${ pkgs.coreutils }/bin/echo ${ foobar.shell-script } &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ foobar.tests } &&
                                                                            if [ -f ${ foobar.tests }/SUCCESS ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo "There was success in ${ foobar.tests }."
                                                                            elif [ -f ${ foobar.tests }/FAILURE ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo "There was a predicted failure in ${ foobar.tests }" >&2 &&
                                                                                    exit 63
                                                                            else
                                                                                ${ pkgs.coreutils }/bin/echo "There was an unpredicted failure in ${ foobar.tests }" >&2 &&
                                                                                    exit 62
                                                                            fi
                                                                    '' ;
                                                        name = "foobar" ;
                                                        src = ./. ;
                                                    } ;
                                            vacuum =
                                                pkgs.stdenv.mkDerivation
                                                    {
                                                        installPhase =
                                                            ''
                                                                ${ pkgs.coreutils }/bin/touch $out &&
                                                                    ${ pkgs.coreutils }/bin/echo ${ vacuum.shell-script } &&
                                                                    ${ pkgs.coreutils }/bin/echo ${ vacuum.tests } &&
                                                                    if [ -f ${ vacuum.tests }/SUCCESS ]
                                                                    then
                                                                        ${ pkgs.coreutils }/bin/echo "There was success in ${ vacuum.tests }."
                                                                    elif [ -f ${ vacuum.tests }/FAILURE ]
                                                                    then
                                                                        ${ pkgs.coreutils }/bin/echo "There was a predicted failure in ${ vacuum.tests }" >&2 &&
                                                                            exit 63
                                                                    else
                                                                        ${ pkgs.coreutils }/bin/echo "There was an unpredicted failure in ${ vacuum.tests }" >&2 &&
                                                                            exit 62
                                                                    fi
                                                            '' ;
                                                        name = "vacuum" ;
                                                        src = ./. ;
                                                    } ;
                                        } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}