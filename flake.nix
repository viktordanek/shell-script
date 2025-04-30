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
                                                delay =
                                                    ignore :
                                                        {
                                                            delay = true ;
                                                            mounts =
                                                                {
                                                                    "/singleton" =
                                                                        {
                                                                            expected = self + "/expected/foobar/delay/mounts/singleton" ;
                                                                            initial =
                                                                                [
                                                                                    "echo e74fcd9b58590b3f2bc961c40b63741057d4659d630042d0283f32f42c2a1854eb948dd7ea7f65a18d38e2e0c872c4a79dd6b0ba0799b73540407430090b2f0f > /mount/target"
                                                                                ] ;
                                                                        } ;
                                                                } ;
                                                            standard-error = self + "/expected/foobar/delay/standard-error" ;
                                                            standard-output = self + "/expected/foobar/delay/standard-output" ;
                                                            status = 182 ;
                                                            test =
                                                                [
                                                                    # "${ pkgs.which }/bin/which candidate" ## FIXME
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
                            lib =
                                {
                                    extensions ? { } ,
                                    mounts ? { } ,
                                    name ,
                                    profile ? null ,
                                    script ,
                                    sleep ? 0 ,
                                    tests ? null ,
                                    trace ? false ,
                                    over-initialized-target-error-code ? 66
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
                                                    if builtins.typeOf script == "set" then builtins.toString script
                                                    else if builtins.typeOf script == "string" then
                                                        if builtins.match "^/.*" script != null then
                                                            if builtins.pathExists script then pkgs.writeShellScript "script" ( builtins.readFile script )
                                                            else builtins.throw "script is an absolute path but there does not exist a path for ${ script }."
                                                        else pkgs.writeShellScript "script" script
                                                    else builtins.throw "script is not set, string but ${ builtins.typeOf script }." ;
                                                sleep =
                                                    if builtins.typeOf sleep == "int" then builtins.toString sleep
                                                    else builtins.throw "sleep is not int but ${ builtins.typeOf sleep }." ;
                                                tests =
                                                    if builtins.typeOf tests == "null" then tests
                                                    else if builtins.typeOf tests == "list" then tests
                                                    else if builtins.typeOf tests == "set" then tests
                                                    else builtins.throw "tests is not null, list, set but ${ builtins.typeOf tests }." ;
                                                trace =
                                                    if builtins.typeOf trace == "bool" then trace
                                                    else builtins.throw "trace is not bool but ${ builtins.typeOf trace }." ;
                                                over-initialized-target-error-code =
                                                    if builtins.typeOf over-initialized-target-error-code == "int" then builtins.toString over-initialized-target-error-code
                                                    else builtins.throw "over-initialized-target-error-code is not int but ${ builtins.typeOf over-initialized-target-error-code }." ;
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
                                                                    constructor =
                                                                        builtins.concatStringsSep
                                                                            " &&\n\t"
                                                                            (
                                                                                let
                                                                                    metrics =
                                                                                        _visitor
                                                                                            {
                                                                                                lambda =
                                                                                                    path : value :
                                                                                                        let
                                                                                                            delayed = if builtins.pathExists "${ derivation }/DELAYED" && ! ( builtins.pathExists "${ derivation }/ERROR" || builtins.pathExists "${ derivation }/FAILURE" || builtins.pathExists "${ derivation }/SUCCESS" ) then true else false ;
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
                                                                                                                                                        ]
                                                                                                                                                        [
                                                                                                                                                            "${ _environment-variable "MKDIR" } ${ _environment-variable "OUT" }/expected/mounts"
                                                                                                                                                        ]
                                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { expected , ... } : "${ _environment-variable "CP" } --recursive ${ expected } ${ _environment-variable "OUT" }/expected/mounts/${ builtins.hashString "sha512" name }" ) secondary.mounts ) )
                                                                                                                                                        [
                                                                                                                                                            "source ${ _environment-variable "MAKE_WRAPPER" }/nix-support/setup-hook"
                                                                                                                                                        ]
                                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { initial , ... } : "${ _environment-variable "LN" } --symbolic ${ initial } ${ _environment-variable "OUT" }/bin/initial.${ builtins.hashString "sha512" name }.sh" ) secondary.mounts ) )
                                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "makeWrapper ${ _environment-variable "OUT" }/bin/initial.${ builtins.hashString "sha512" name }.sh ${ _environment-variable "OUT" }/bin/initial.${ builtins.hashString "sha512" name }.wrapped.sh"  ) secondary.mounts ) )
                                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "makeWrapper ${ pkgs.writeShellScript "initial" ( builtins.readFile ( self + "/initial.sh" ) ) } ${ _environment-variable "OUT" }/bin/initial.${ builtins.hashString "sha512" name }.guarded.sh --set CP ${ _environment-variable "CP" } --set DRAFT ${ _environment-variable "OUT" }/bin/initial.${ builtins.hashString "sha512" name }.sh --set INITIAL ${ _environment-variable "OUT" }/bin/initial.${ builtins.hashString "sha512" name }.guarded.sh --set CAT ${ _environment-variable "CAT" } --set ECHO ${ _environment-variable "ECHO" } --set FIND ${ _environment-variable "FIND" } --set INITIAL ${ _environment-variable "OUT" }/bin/initial.${ builtins.hashString "sha512" name }.wrapped.sh --set LN ${ _environment-variable "LN" } --set MKDIR ${ _environment-variable "MKDIR" } --set WC ${ _environment-variable "WC" }" ) secondary.mounts ) )
                                                                                                                                                        (
                                                                                                                                                            let
                                                                                                                                                                mapper =
                                                                                                                                                                    name : { ... } :
                                                                                                                                                                        let
                                                                                                                                                                            user-environment =
                                                                                                                                                                                pkgs.buildFHSUserEnv
                                                                                                                                                                                    {
                                                                                                                                                                                        extraBwrapArgs = [ "--bind /work/initial/${ builtins.hashString "sha512" name } /initial" "--bind /work/mounts/${ builtins.hashString "sha512" name } /mount" ] ;
                                                                                                                                                                                        name = "initial" ;
                                                                                                                                                                                        runScript = "${ _environment-variable "OUT" }/bin/initial.${ builtins.hashString "sha512" name }.guarded.sh" ;
                                                                                                                                                                                    } ;
                                                                                                                                                                            in "${ _environment-variable "LN" } --symbolic ${ user-environment }/bin/initial ${ _environment-variable "OUT" }/bin/initial.${ builtins.hashString "sha512" name }.shelled.sh" ;
                                                                                                                                                                in builtins.attrValues ( builtins.mapAttrs mapper secondary.mounts )
                                                                                                                                                        )
                                                                                                                                                        [
                                                                                                                                                            "${ _environment-variable "LN" } --symbolic ${ secondary.test } ${ _environment-variable "OUT" }/bin/test.sh"
                                                                                                                                                            (
                                                                                                                                                                let
                                                                                                                                                                    candidate =
                                                                                                                                                                        shell-script
                                                                                                                                                                            {
                                                                                                                                                                                mounts = builtins.mapAttrs ( name : { is-read-only , ... } : { host-path = "/work/mounts/${ builtins.hashString "sha512" name }/target" ; is-read-only = is-read-only ; } ) secondary.mounts ;
                                                                                                                                                                                name = "candidate" ;
                                                                                                                                                                                profile = secondary.profile ;
                                                                                                                                                                            } ;
                                                                                                                                                                    in "makeWrapper ${ _environment-variable "OUT" }/bin/test.sh ${ _environment-variable "OUT" }/bin/test.wrapped.sh --set PATH ${ pkgs.coreutils }/bin:${ candidate }/bin"
                                                                                                                                                            )
                                                                                                                                                            "makeWrapper ${ pkgs.writeShellScript "test" ( builtins.readFile ( self + "/test.sh" ) ) } ${ _environment-variable "OUT" }/bin/test.guarded.sh --set ECHO ${ _environment-variable "ECHO" } --set TEST ${ _environment-variable "OUT" }/bin/test.wrapped.sh"
                                                                                                                                                        ]
                                                                                                                                                        [
                                                                                                                                                            "${ _environment-variable "LN" } --symbolic ${ pkgs.writeShellScript "vacuum" ( builtins.readFile ( self + "/vacuum2.sh" ) ) } ${ _environment-variable "OUT" }/bin/vacuum.sh"
                                                                                                                                                            "makeWrapper ${ _environment-variable "OUT" }/bin/vacuum.sh ${ _environment-variable "OUT" }/bin/vacuum.wrapped.sh --set CAT ${ _environment-variable "CAT" } --set CHMOD ${ _environment-variable "CHMOD" } --set CUT ${ _environment-variable "CUT" } --set ECHO ${ _environment-variable "ECHO" } --set DATE ${ _environment-variable "DATE" } --set FIND ${ _environment-variable "FIND" } --set SHA512SUM ${ _environment-variable "SHA512SUM" } --set STAT ${ _environment-variable "STAT" } --set WC ${ _environment-variable "WC" }"
                                                                                                                                                        ]
                                                                                                                                                        (
                                                                                                                                                            let
                                                                                                                                                                mapper =
                                                                                                                                                                    name : { ... } :
                                                                                                                                                                        let
                                                                                                                                                                            user-environment =
                                                                                                                                                                                pkgs.buildFHSUserEnv
                                                                                                                                                                                    {
                                                                                                                                                                                        extraBwrapArgs = [ "--ro-bind /work/mounts/${ builtins.hashString "sha512" name }/target /input" "--bind /work/final/mounts/${ builtins.hashString "sha512" name } /output" ] ;
                                                                                                                                                                                        name = "vacuum" ;
                                                                                                                                                                                        runScript = "${ _environment-variable "OUT" }/bin/vacuum.wrapped.sh" ;
                                                                                                                                                                                    } ;
                                                                                                                                                                            in "${ _environment-variable "LN" } --symbolic ${ user-environment }/bin/vacuum ${ _environment-variable "OUT" }/bin/vacuum.${ builtins.hashString "sha512" name }.shelled.sh" ;
                                                                                                                                                                in builtins.attrValues ( builtins.mapAttrs mapper secondary.mounts )
                                                                                                                                                        )
                                                                                                                                                        [
                                                                                                                                                            (
                                                                                                                                                                let
                                                                                                                                                                    observe =
                                                                                                                                                                        builtins.concatStringsSep
                                                                                                                                                                            " &&\n\t"
                                                                                                                                                                            (
                                                                                                                                                                                builtins.concatLists
                                                                                                                                                                                    [
                                                                                                                                                                                        [
                                                                                                                                                                                            "${ _environment-variable "MKDIR" } /work/initial"
                                                                                                                                                                                            "${ _environment-variable "MKDIR" } /work/mounts"
                                                                                                                                                                                        ]
                                                                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "${ _environment-variable "MKDIR" } /work/initial/${ builtins.hashString "sha512" name }" ) secondary.mounts ) )
                                                                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "${ _environment-variable "MKDIR" } /work/mounts/${ builtins.hashString "sha512" name }" ) secondary.mounts ) )
                                                                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "${ _environment-variable "OUT" }/bin/initial.${ builtins.hashString "sha512" name }.shelled.sh" ) secondary.mounts ) )
                                                                                                                                                                                        [
                                                                                                                                                                                            "${ _environment-variable "MKDIR" } /work/final"
                                                                                                                                                                                            "${ _environment-variable "OUT" }/bin/test.guarded.sh"
                                                                                                                                                                                            "${ _environment-variable "MKDIR" } /work/final/mounts"
                                                                                                                                                                                        ]
                                                                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "${ _environment-variable "MKDIR" } /work/final/mounts/${ builtins.hashString "sha512" name }" ) secondary.mounts ) )
                                                                                                                                                                                        [
                                                                                                                                                                                            "${ _environment-variable "SLEEP" } ${ primary.sleep }s"
                                                                                                                                                                                        ]
                                                                                                                                                                                        ( builtins.attrValues ( builtins.mapAttrs ( name : { ... } : "${ _environment-variable "OUT" }/bin/vacuum.${ builtins.hashString "sha512" name }.shelled.sh" ) secondary.mounts ) )
                                                                                                                                                                                        [
                                                                                                                                                                                            "if ${ _environment-variable "DIFF" } --recursive ${ if primary.trace then "" else "--exclude trace" } ${ _environment-variable "OUT" }/expected ${ _environment-variable "WORK" }/final > ${ _environment-variable "WORK" }/diff ; then ${ _environment-variable "TOUCH" } ${ _environment-variable "WORK" }/SUCCESS ; else ${ _environment-variable "TOUCH" } ${ _environment-variable "WORK" }/FAILURE && exit 64 ; fi"
                                                                                                                                                                                        ]
                                                                                                                                                                                    ]
                                                                                                                                                                            ) ;
                                                                                                                                                                        in "${ _environment-variable "LN" } --symbolic ${ pkgs.writeShellScript "observe" observe } ${ _environment-variable "OUT" }/bin/observe.sh"
                                                                                                                                                            )
                                                                                                                                                            "makeWrapper ${ _environment-variable "OUT" }/bin/observe.sh ${ _environment-variable "OUT" }/bin/observe.wrapped.sh --set CAT ${ _environment-variable "CAT" } --set DIFF ${ _environment-variable "DIFF" } --set MKDIR ${ _environment-variable "MKDIR" } --set OUT $out --set SLEEP ${ _environment-variable "SLEEP" } --set TOUCH ${ _environment-variable "TOUCH" }"
                                                                                                                                                            (
                                                                                                                                                                let
                                                                                                                                                                    user-environment =
                                                                                                                                                                        pkgs.buildFHSUserEnv
                                                                                                                                                                            {
                                                                                                                                                                                extraBwrapArgs = [ "--bind ${ _environment-variable "WORK" } /work" ] ;
                                                                                                                                                                                name = "observe" ;
                                                                                                                                                                                runScript = "${ _environment-variable "OUT" }/bin/observe.wrapped.sh" ;
                                                                                                                                                                            } ;
                                                                                                                                                                    in "${ _environment-variable "LN" } --symbolic ${ user-environment }/bin/observe ${ _environment-variable "OUT" }/bin/observe.shelled.sh"
                                                                                                                                                            )
                                                                                                                                                        ]
                                                                                                                                                        (
                                                                                                                                                            if secondary.delay then
                                                                                                                                                                [
                                                                                                                                                                    "${ _environment-variable "TOUCH" } ${ _environment-variable "OUT" }/DELAYED"
                                                                                                                                                                ]
                                                                                                                                                            else
                                                                                                                                                                [
                                                                                                                                                                    "export WORK=/build/work"
                                                                                                                                                                    "${ _environment-variable "MKDIR" } ${ _environment-variable "WORK" }"
                                                                                                                                                                    "${ _environment-variable "OUT" }/bin/observe.shelled.sh"
                                                                                                                                                                    "${ _environment-variable "CP" } --recursive ${ _environment-variable "WORK" }/* ${ _environment-variable "OUT" }"
                                                                                                                                                                ]
                                                                                                                                                        )
                                                                                                                                                    ]
                                                                                                                                            ) ;
                                                                                                                                in
                                                                                                                                    ''
                                                                                                                                        ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                                                                            ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                                                                                            ${ pkgs.coreutils }/bin/ln --symbolic ${ pkgs.writeShellScript "constructors" constructors } $out/bin/constructors.sh &&
                                                                                                                                            makeWrapper $out/bin/constructors.sh $out/bin/constructors --set BASENAME ${ pkgs.coreutils }/bin/basename --set CAT ${ pkgs.coreutils }/bin/cat --set CHMOD ${ pkgs.coreutils }/bin/chmod --set CP ${ pkgs.coreutils }/bin/cp --set CUT ${ pkgs.coreutils }/bin/cut --set DIFF ${ pkgs.diffutils }/bin/diff --set DATE ${ pkgs.coreutils }/bin/date --set ECHO ${ pkgs.coreutils }/bin/echo --set FIND ${ pkgs.findutils }/bin/find --set LN ${ pkgs.coreutils }/bin/ln --set MKDIR ${ pkgs.coreutils }/bin/mkdir --set MAKE_WRAPPER ${ pkgs.makeWrapper } --set MV ${ pkgs.coreutils }/bin/mv --set OUT $out --set SHA512SUM ${ pkgs.coreutils }/bin/sha512sum --set SLEEP ${ pkgs.coreutils }/bin/sleep --set SORT ${ pkgs.coreutils }/bin/sort --set STAT ${ pkgs.coreutils }/bin/stat --set TOUCH ${ pkgs.coreutils }/bin/touch --set VACUUM ${ vacuum.shell-script } --set WC ${ pkgs.coreutils }/bin/wc &&
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
                                                                                                                            delay ? false ,
                                                                                                                            mounts ? { } ,
                                                                                                                            profile ? null ,
                                                                                                                            standard-error ? "" ,
                                                                                                                            standard-output ? "" ,
                                                                                                                            status ? 0 ,
                                                                                                                            initial ? "initial" ,
                                                                                                                            test ? "candidate"
                                                                                                                        } :
                                                                                                                            {
                                                                                                                                delay =
                                                                                                                                    if builtins.typeOf delay == "bool" then delay
                                                                                                                                    else builtins.throw "delay is not bool but ${ builtins.typeOf delay }." ;
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
                                                                                                                                                                if builtins.typeOf initial == "list" then pkgs.writeShellScript "initial" ( builtins.concatStringsSep " &&\n\t" ( builtins.map ( value : if builtins.typeOf value == "string" then value else builtins.throw "initial is not string but ${ builtins.typeOf value }." ) initial ) )
                                                                                                                                                                else if builtins.typeOf initial == "string" then initial
                                                                                                                                                                else builtins.throw "initial is not list, string but ${ builtins.typeOf initial }." ;
                                                                                                                                                            initial-path = "/build/initial.${ builtins.hashString "sha512" name }" ;
                                                                                                                                                            is-read-only = builtins.getAttr "is-read-only" ( builtins.getAttr name primary.mounts ) ;
                                                                                                                                                            observed-path = "${ _environment-variable "OUT" }/observed/${ builtins.hashString "sha512" name }" ;
                                                                                                                                                            test-path = "${ _environment-variable "OUT" }/test/initial.${ builtins.hashString "sha512" name }" ;
                                                                                                                                                            vacuum-path = "/build/vacuum.${ builtins.hashString "sha512" name }" ;
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
                                                                                                                                    if builtins.typeOf test == "string" then pkgs.writeShellScript "tests" test
                                                                                                                                    else if builtins.typeOf test == "list" then
                                                                                                                                        let
                                                                                                                                            mapper = value : if builtins.typeOf value == "string" then value else builtins.throw "test is not string but ${ builtins.typeOf value }." ;
                                                                                                                                            in pkgs.writeShellScript "tests" ( builtins.concatStringsSep " &&\n\t" ( builtins.map mapper test ) )
                                                                                                                                    else builtins.throw "test is not string but ${ builtins.typeOf test }." ;
                                                                                                                            } ;
                                                                                                                in identity ( value null ) ;
                                                                                                            failure = if builtins.pathExists "${ derivation }/FAILURE" && ! ( builtins.pathExists "${ derivation }/DELAYED" || builtins.pathExists "${ derivation }/SUCCESS" ) then true else false ;
                                                                                                            no = [ ] ;
                                                                                                            success = if builtins.pathExists "${ derivation }/SUCCESS" && ! ( builtins.pathExists "${ derivation }/DELAYED" || builtins.pathExists "${ derivation }/FAILURE" ) then true else false ;
                                                                                                            yes = [ { path = path ; value = derivation ; } ] ;
                                                                                                            in
                                                                                                                {
                                                                                                                    all = yes ;
                                                                                                                    delayed = if delayed then yes else no ;
                                                                                                                    error =
                                                                                                                        if builtins.pathExists "${ derivation }/ERROR" then yes
                                                                                                                        else if ! ( delayed || failure || success ) then yes
                                                                                                                        else no ;
                                                                                                                    failure = if failure then yes else no ;
                                                                                                                    success = if success then yes else no ;
                                                                                                                } ;
                                                                                                list =
                                                                                                    path : list :
                                                                                                        {
                                                                                                            all = builtins.concatLists ( builtins.map ( l : l.all ) list ) ;
                                                                                                            delayed = builtins.concatLists ( builtins.map ( l : l.delayed ) list ) ;
                                                                                                            error = builtins.concatLists ( builtins.map ( l : l.error ) list ) ;
                                                                                                            failure = builtins.concatLists ( builtins.map ( l : l.failure ) list ) ;
                                                                                                            success = builtins.concatLists ( builtins.map ( l : l.success ) list ) ;
                                                                                                        } ;
                                                                                                null =
                                                                                                    path : value :
                                                                                                        {
                                                                                                            all = [ ] ;
                                                                                                            delayed = [ ] ;
                                                                                                            error = [ ] ;
                                                                                                            failure = [ ] ;
                                                                                                            success = [ ] ;
                                                                                                        } ;
                                                                                                set =
                                                                                                    path : set :
                                                                                                        {
                                                                                                            all = builtins.concatLists ( builtins.attrValues ( builtins.mapAttrs ( name : value : value.all ) set ) ) ;
                                                                                                            delayed = builtins.concatLists ( builtins.attrValues ( builtins.mapAttrs ( name : value : value.delayed ) set ) ) ;
                                                                                                            error = builtins.concatLists ( builtins.attrValues ( builtins.mapAttrs ( name : value : value.error ) set ) ) ;
                                                                                                            failure = builtins.concatLists ( builtins.attrValues ( builtins.mapAttrs ( name : value : value.failure ) set ) ) ;
                                                                                                            success = builtins.concatLists ( builtins.attrValues ( builtins.mapAttrs ( name : value : value.success ) set ) ) ;
                                                                                                        } ;
                                                                                            }
                                                                                            tests ;
                                                                                    in
                                                                                        [
                                                                                            "${ _environment-variable "ECHO" } '${ builtins.toJSON metrics }' | ${ _environment-variable "YQ" } --yaml-output > ${ _environment-variable "OUT" }/metrics.yaml"
                                                                                            (
                                                                                                let
                                                                                                    status =
                                                                                                        if builtins.length metrics.all == builtins.length metrics.success && builtins.length metrics.delayed == 0 && builtins.length metrics.error == 0 && builtins.length metrics.failure == 0 then "SUCCESS"
                                                                                                        else if builtins.length metrics.all == ( builtins.length metrics.success ) + ( builtins.length metrics.delayed ) && builtins.length metrics.error == 0 && builtins.length metrics.failure == 0 then "DELAYED"
                                                                                                        else if builtins.length metrics.all == ( builtins.length metrics.success ) + ( builtins.length metrics.delayed ) + ( builtins.length metrics.failure ) && builtins.length metrics.error == 0 then "FAILURE"
                                                                                                        else "ERROR" ;
                                                                                                    in "${ _environment-variable "TOUCH" } ${ _environment-variable "OUT" }/${ status }"
                                                                                            )
                                                                                            "source ${ _environment-variable "MAKE_WRAPPER" }/nix-support/setup-hook"
                                                                                            (
                                                                                                let
                                                                                                    observe =
                                                                                                        let
                                                                                                            delayed =
                                                                                                                let
                                                                                                                    mapper =
                                                                                                                        value :
                                                                                                                            [
                                                                                                                                "export WORK=$( ${ _environment-variable "MKTEMP" } --directory )"
                                                                                                                                "export OUT=${ value.value }"
                                                                                                                                ''${ _environment-variable "ECHO" } "  - path: ${ builtins.replaceStrings [ "\"" ] [ "\\\"" ] ( builtins.concatStringsSep " / " ( builtins.map builtins.toJSON value.path ) ) }"''
                                                                                                                                ''${ _environment-variable "ECHO" } "    out: ${ _environment-variable "OUT" }"''
                                                                                                                                ''${ _environment-variable "ECHO" } "    work: ${ _environment-variable "WORK" }"''
                                                                                                                                ''if ${ _environment-variable "OUT" }/bin/observe.shelled.sh ; then ${ _environment-variable "ECHO" } "    status: SUCCESS" ; else ${ _environment-variable "ECHO" } "    status: FAILURE" && exit 64 ; fi''
                                                                                                                            ] ;
                                                                                                                    in builtins.concatLists ( builtins.map mapper metrics.delayed ) ;
                                                                                                            error =
                                                                                                                let
                                                                                                                    mapper =
                                                                                                                        value :
                                                                                                                            [
                                                                                                                                ''${ _environment-variable "ECHO" } "- path: ${ builtins.replaceStrings [ "\"" ] [ "\\\"" ] ( builtins.concatStringsSep " / " ( builtins.map builtins.toJSON value.path ) ) }"''
                                                                                                                                "export OUT=${ value.value }"
                                                                                                                                ''${ _environment-variable "ECHO" } "  out: ${ _environment-variable "OUT" }"''
                                                                                                                                ''${ _environment-variable "ECHO" } "  status: ERROR"''
                                                                                                                                 "exit 64"
                                                                                                                            ] ;
                                                                                                                    in builtins.concatLists ( builtins.map mapper metrics.error ) ;
                                                                                                            failure =
                                                                                                                let
                                                                                                                    mapper =
                                                                                                                        value :
                                                                                                                            [
                                                                                                                                ''${ _environment-variable "ECHO" } "- path: ${ builtins.replaceStrings [ "\"" ] [ "\\\"" ] ( builtins.concatStringsSep " / " ( builtins.map builtins.toJSON value.path ) ) }"''
                                                                                                                                "export OUT=${ value.value }"
                                                                                                                                ''${ _environment-variable "ECHO" } "  out: ${ _environment-variable "OUT" }"''
                                                                                                                                ''${ _environment-variable "ECHO" } "  status: ERROR"''
                                                                                                                                "exit 64"
                                                                                                                            ] ;
                                                                                                                    in builtins.concatLists ( builtins.map mapper metrics.failure ) ;
                                                                                                            success =
                                                                                                                let
                                                                                                                    mapper =
                                                                                                                        value :
                                                                                                                            [
                                                                                                                                ''${ _environment-variable "ECHO" } "- path: ${ builtins.replaceStrings [ "\"" ] [ "\\\"" ] ( builtins.concatStringsSep " / " ( builtins.map builtins.toJSON value.path ) ) }"''
                                                                                                                                "export OUT=${ value.value }"
                                                                                                                                ''${ _environment-variable "ECHO" } "  out: ${ _environment-variable "OUT" }"''
                                                                                                                                ''${ _environment-variable "ECHO" } "  status: SUCCESS"''
                                                                                                                            ] ;
                                                                                                                    in builtins.concatLists ( builtins.map mapper metrics.success ) ;
                                                                                                            in builtins.concatStringsSep " &&\n\t" ( builtins.concatLists [ error failure delayed success ] ) ;
                                                                                                    in
                                                                                                    "makeWrapper ${ pkgs.writeShellScript "observe.sh" observe } ${ _environment-variable "OUT" }/observe.wrapped.sh --set ECHO ${ _environment-variable "ECHO" } --set MKTEMP ${ _environment-variable "MKTEMP" } --set RM ${ _environment-variable "RM" }"
                                                                                            )
                                                                                        ]
                                                                            ) ;
                                                                    in
                                                                        ''
                                                                            ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                ${ pkgs.coreutils }/bin/ln --symbolic ${ pkgs.writeShellScript "constructor.sh" constructor } $out/constructor.sh &&
                                                                                makeWrapper $out/constructor.sh $out/constructor.wrapped.sh --set ECHO ${ pkgs.coreutils }/bin/echo --set MAKE_WRAPPER ${ pkgs.makeWrapper } --set MKTEMP ${ pkgs.coreutils }/bin/mktemp --set OUT $out --set RM ${ pkgs.coreutils }/bin/rm --set TOUCH ${ pkgs.coreutils }/bin/touch --set YQ ${ pkgs.yq }/bin/yq &&
                                                                                $out/constructor.wrapped.sh
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
                                                "/input" =
                                                    {
                                                        host-path = _environment-variable "INPUT" ;
                                                        is-read-only = true ;
                                                    } ;
                                                "/output" =
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
                                                    ( string "DATE" "${ pkgs.coreutils }/bin/date" )
                                                    ( string "ECHO" "${ pkgs.coreutils }/bin/echo" )
                                                    ( string "FIND" "${ pkgs.findutils }/bin/find" )
                                                    ( string "MKDIR" "${ pkgs.coreutils }/bin/mkdir" )
                                                    ( string "SHA512SUM" "${ pkgs.coreutils }/bin/sha512sum" )
                                                    ( string "STAT" "${ pkgs.coreutils }/bin/stat" )
                                                    ( string "UUID" "706fd7726e3d7fd7fbd98a95c3222049fbe419934cbd41dcf324a6a004b69b561b6304d2b4030df318ee1cbd20cd74a1524d1f74116a2b900979ba66ed4eadc8" )
                                                    ( string "WC" "${ pkgs.coreutils }/bin/wc" )
                                                ] ;
                                        script = self + "/vacuum2.sh" ;
                                        tests =
                                            ignore :
                                                {
                                                    mounts =
                                                        {
                                                            "/input" =
                                                                {
                                                                    expected = self + "/expected/vacuum/mounts/input" ;
                                                                    initial =
                                                                        [
                                                                            "echo 3275d3d7a12620ea996ca571c341cd66258f413f11796a3a596de316fbd4477b34b1251a10a38044b98e1f757343102f4848e77961aae44e916ef0b2b1c2070c > /mount/target"
                                                                        ] ;
                                                                } ;
                                                            "/output" =
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
                                    apps =
                                        {
                                            foobar =
                                                {
                                                    type = "app" ;
                                                    program =
                                                        builtins.toString
                                                            (
                                                                pkgs.writeShellScript
                                                                    "foobar"
                                                                    ''
                                                                        ${ foobar.tests }/observe.wrapped.sh
                                                                    ''
                                                            ) ;
                                                } ;
                                            vacuum =
                                                {
                                                    type = "app" ;
                                                    program = vacuum.shell-script ;
                                                } ;
                                        } ;
                                    checks =
                                        {
                                            foobar =
                                                pkgs.stdenv.mkDerivation
                                                    {
                                                        installPhase =
                                                            let
                                                                in
                                                                    ''
                                                                        ${ pkgs.coreutils }/bin/touch $out &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ foobar.shell-script } &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ foobar.tests } &&
                                                                            if [ -f ${ foobar.tests }/SUCCESS ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo "There was success in ${ foobar.tests }." &&
                                                                                exit 63
                                                                            elif [ -f ${ foobar.tests }/DELAYED ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo "There was delay in ${ foobar.tests }."
                                                                            elif [ -f ${ foobar.tests }/FAILURE ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo "There was failure in ${ foobar.tests }" >&2 &&
                                                                                    exit 61
                                                                            else
                                                                                ${ pkgs.coreutils }/bin/echo "There was error in ${ foobar.tests }" >&2 &&
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
                                                                            ${ pkgs.coreutils }/bin/echo ${ simple.shell-script } &&
                                                                            if [ -f ${ simple.tests }/SUCCESS ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo There was success in ${ simple.tests }.
                                                                            elif [ -f ${ simple.tests }/FAILURE ]
                                                                            then
                                                                                ${ pkgs.coreutils }/bin/echo There was failure in ${ simple.tests }. >&2 &&
                                                                                    exit 63
                                                                            else
                                                                                ${ pkgs.coreutils }/bin/echo There was error in ${ simple.tests }. >&2 &&
                                                                                    exit 62
                                                                            fi
                                                                    '' ;
                                                        name = "simple" ;
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
                                    vacuum = vacuum ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}