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
                                    default-name ? "script" ,
                                    extensions ? [ ] ,
                                    mounts ? { } ,
                                    shell-scripts ? null
                                } :
                                    let
                                        _visitor = builtins.getAttr system visitor.lib ;
                                        primary =
                                            {
                                                default-name = if builtins.typeOf default-name == "string" then default-name else builtins.throw "default-name is not string but ${ builtins.typeOf default-name }." ;
                                                extensions = if builtins.typeOf extensions == "list" then extensions else builtins.throw "extensions is not list but ${ builtins.typeOf extensions }." ;
                                                mounts =
                                                    if builtins.typeOf mounts == "set" then
                                                        let
                                                            mapper = name : value : if builtins.typeOf value == "string" then value else builtins.throw "The ${ name } attribute of mounts is not string but ${ builtins.typeOf value }." ;
                                                                in builtins.mapAttrs mapper mounts
                                                    else builtins.throw "mounts is not set but ${ builtins.typeOf mounts }." ;
                                                shell-scripts =
                                                    _visitor
                                                        {
                                                            lambda =
                                                                path : value :
                                                                    let
                                                                        identity =
                                                                            { environment ? { ... } : [ ] , script , tests ? null } :
                                                                                {
                                                                                    environment = environment ;
                                                                                    script =
                                                                                        if builtins.typeOf pkgs == "set" then
                                                                                            let
                                                                                                eval = builtins.tryEval ( builtins.toString script ) ;
                                                                                                in if eval.success then eval.value else builtins.throw "The script defined at ${ builtins.concatStringsSep " / " ( builtins.map builtins.toJSON path ) } is a set but not stringable."
                                                                                        else if builtins.typeOf script == "string" then script
                                                                                        else throw [ "string" "set" ] path value ;
                                                                                    tests = tests ;
                                                                                } ;
                                                                        in ignore : identity ( value null ) ;
                                                        }
                                                        { }
                                                        shell-scripts ;
                                            } ;
                                        derivation =
                                            pkgs.stdenv.mkDerivation
                                                {
                                                    installPhase =
                                                        let
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
                                                                                                    ''
                                                                                                        ${ pkgs.coreutils }/bin/cat ${ secondary.script } > $out &&
                                                                                                            ${ pkgs.coreutils }/bin/chmod 0555 $out
                                                                                                    '' ;
                                                                                                name = builtins.concatStringsSep "/" ( builtins.map builtins.toJSON path ) ;
                                                                                                src = ./. ;
                                                                                            } ;
                                                                                    secondary =
                                                                                        let
                                                                                            identity =
                                                                                                {
                                                                                                    environment ,
                                                                                                    script ,
                                                                                                    tests
                                                                                                } :
                                                                                                    {
                                                                                                        environment =
                                                                                                            let
                                                                                                                injection =
                                                                                                                    [
                                                                                                                        { name = "path" ; value = name : index : "--set ${ name } ${ builtins.toString ( builtins.elemAt path index ) }" ; }
                                                                                                                        {
                                                                                                                            name = "self" ;
                                                                                                                            value =
                                                                                                                                name : lambda :
                                                                                                                                    let
                                                                                                                                        self =
                                                                                                                                            _visitor
                                                                                                                                                {
                                                                                                                                                    lambda = path : value : builtins.concatStringsSep "" ( builtins.map builtins.toJSON path ) ;
                                                                                                                                                }
                                                                                                                                                { }
                                                                                                                                                primary.shell-scripts ;
                                                                                                                                        in "--set ${ name } $out/${ builtins.toString ( lambda self ) }" ;
                                                                                                                        }
                                                                                                                        {
                                                                                                                            name = "standard-input" ;
                                                                                                                            value = { name ? "STANDARD_INPUT" } : "--run 'export ${ name }=$( if [ -f /proc/self/fd/0 ] || [ -p /proc/self/fd/0 ] ; then ${ pkgs.coreutils }/bin/cat ; else ${ pkgs.coreutils }/bin/echo ; fi )'" ;
                                                                                                                        }
                                                                                                                        { name = "string" ; value = name : value : "--set ${ name } ${ builtins.toString value }" ; }
                                                                                                                    ] ;
                                                                                                                in environment ( builtins.listToAttrs ( builtins.concatLists [ injection extensions ] ) ) ;
                                                                                                        script =
                                                                                                            if builtins.typeOf script == "string" then script
                                                                                                            else throw [ "string" ] path script ;
                                                                                                    } ;
                                                                                            in identity ( value null ) ;
                                                                                    in
                                                                                        [
                                                                                            "makeWrapper ${ derivation } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] path ] ) } ${ builtins.concatStringsSep " " secondary.environment }"
                                                                                        ] ;
                                                                    }
                                                                    {
                                                                        list =
                                                                            path : list :
                                                                                builtins.concatLists
                                                                                    [
                                                                                        [
                                                                                            "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] path ] ) }"
                                                                                        ]
                                                                                        ( builtins.concatLists list )
                                                                                    ] ;
                                                                        set =
                                                                            path : set :
                                                                                builtins.concatLists
                                                                                    [
                                                                                        [
                                                                                            "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out"  ] path ] ) }"
                                                                                        ]
                                                                                        ( builtins.concatLists ( builtins.attrValues set ) )
                                                                                    ] ;

                                                                    }
                                                                    primary.shell-scripts ;
                                                            in builtins.concatStringsSep " &&\n\t" constructors ;
                                                    name = "shell-scripts" ;
                                                    nativeBuildInputs = [ pkgs.makeWrapper ] ;
                                                    src = ./. ;
                                                } ;
                                    in
                                        {
                                            shell-scripts =
                                                _visitor
                                                    {
                                                        lambda =
                                                            path : value :
                                                                let
                                                                    name =
                                                                        if builtins.length path > 0 then builtins.elemAt path ( ( builtins.length path ) - 1 )
                                                                        else primary.default-name ;
                                                                    user-environment =
                                                                        pkgs.buildFHSUserEnv
                                                                            {
                                                                                extraBwrapArgs =
                                                                                    let
                                                                                        mapper = sandbox : host : "--bind ${ host } ${ sandbox }" ;
                                                                                        in builtins.concatLists [ [ "--ro-bind ${ derivation } /shell-scripts" ] ( builtins.attrValues ( builtins.mapAttrs mapper primary.mounts ) ) ] ;
                                                                                name = name ;
                                                                                runScript = builtins.concatStringsSep "/" ( builtins.concatLists [ [ "/shell-scripts" ] path ] ) ;
                                                                            } ;
                                                                    in "${ user-environment }/bin/${ name }" ;
                                                    }
                                                    { }
                                                    primary.shell-scripts ;
                                            tests =
                                                pkgs.stdenv.mkDerivation
                                                    {
                                                        installPhase =
                                                            let
                                                                constructors =
                                                                    _visitor
                                                                        {
                                                                            lambda =
                                                                                path : value :
                                                                                    let
                                                                                        candidate =
                                                                                            pkgs.stdenv.mkDerivation
                                                                                                {
                                                                                                    installPhase =
                                                                                                        ''
                                                                                                            ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                                                ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                                                                ${ pkgs.coreutils }/bin/ln --symbolic ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ derivation ] ( builtins.map builtins.toJSON path ) ] ) } $out/bin/candidate
                                                                                                        '' ;
                                                                                                    name = "candidate" ;
                                                                                                    src = ./. ;
                                                                                                } ;
                                                                                        expected = builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) ] ;
                                                                                        observed = builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) ] ;
                                                                                        test = builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) ] ;
                                                                                        point = value null ;
                                                                                        in
                                                                                            _visitor
                                                                                                {
                                                                                                    lambda =
                                                                                                        path : value :
                                                                                                            let
                                                                                                                secondary =
                                                                                                                    let
                                                                                                                        identity =
                                                                                                                            {
                                                                                                                                error ? "" ,
                                                                                                                                mounts ? { } ,
                                                                                                                                output ? "" ,
                                                                                                                                status ? "0" ,
                                                                                                                                test
                                                                                                                            } :
                                                                                                                                {
                                                                                                                                    error = error ;
                                                                                                                                    mounts =
                                                                                                                                        if builtins.typeOf mounts == "set" then
                                                                                                                                            if builtins.attrNames mounts != builtins.attrNames primary.mounts then builtins.throw "The mounts do not match for ${ builtins.concatStringsSep " / " ( builtins.map builtins.toJSON path ) }.  ${ builtins.toJSON mounts } versus ${ builtins.toJSON primary.mounts }."
                                                                                                                                            else
                                                                                                                                                let
                                                                                                                                                    mapper =
                                                                                                                                                        name : { initial , expected } :
                                                                                                                                                            {
                                                                                                                                                                initial = initial ;
                                                                                                                                                                expected = expected ;
                                                                                                                                                            } ;
                                                                                                                                                    in builtins.mapAttrs mapper mounts
                                                                                                                                        else builtins.throw [ "set" ] path mounts ;
                                                                                                                                    output = output ;
                                                                                                                                    status = status ;
                                                                                                                                    test = test ;
                                                                                                                                } ;
                                                                                                                        in identity ( value null ) ;
                                                                                                                user-environment =
                                                                                                                    pkgs.buildFHSUserEnv
                                                                                                                        {
                                                                                                                            extraBwrapArgs =
                                                                                                                                let
                                                                                                                                    generator =
                                                                                                                                        index :
                                                                                                                                            let
                                                                                                                                                sandbox = builtins.elemAt ( builtins.attrNames ( primary.mounts ) ) index ;
                                                                                                                                                in "--bind ${ builtins.concatStringsSep "" [ "$" "{" "MOUNT_" ( builtins.toString index ) "}" ] } ${ sandbox }" ;
                                                                                                                                    in builtins.genList generator ( builtins.length ( builtins.attrValues primary.mounts ) ) ;
                                                                                                                            name = "test-candidate" ;
                                                                                                                            runScript = pkgs.writeShellScript "test" secondary.test ;
                                                                                                                            targetPkgs = pkgs : [ candidate ] ;
                                                                                                                        } ;
                                                                                                                in
                                                                                                                    builtins.concatLists
                                                                                                                        [
                                                                                                                            [
                                                                                                                                "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ expected ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                                "${ pkgs.coreutils }/bin/ln --symbolic ${ builtins.toFile "error" ( builtins.toString secondary.error ) } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ expected ( builtins.map builtins.toJSON path ) [ "error" ] ] ) }"
                                                                                                                            ]
                                                                                                                            (
                                                                                                                                let
                                                                                                                                    generator =
                                                                                                                                        index :
                                                                                                                                            let
                                                                                                                                                mount = builtins.getAttr tag ( secondary.mounts ) ;
                                                                                                                                                tag = builtins.elemAt ( builtins.attrNames primary.mounts ) index ;
                                                                                                                                                in
                                                                                                                                                    [
                                                                                                                                                        "${ pkgs.coreutils }/bin/cp --no-preserve=mode --recursive ${ mount.expected } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ expected ( builtins.map builtins.toJSON path ) [ "mount.${ builtins.toString index }" ] ] ) }"
                                                                                                                                                        "export MOUNT_${ builtins.toString index }=$( ${ pkgs.coreutils }/bin/mktemp --dry-run )"
                                                                                                                                                        "${ pkgs.coreutils }/bin/cp --no-preserve=mode --recursive ${ mount.initial } ${ builtins.concatStringsSep "" [ "$" "{" "MOUNT_" ( builtins.toString index ) "}" ] }"
                                                                                                                                                    ] ;
                                                                                                                                    in builtins.concatLists ( builtins.genList generator ( builtins.length ( builtins.attrValues primary.mounts ) ) )
                                                                                                                            )
                                                                                                                            [
                                                                                                                                "${ pkgs.coreutils }/bin/ln --symbolic ${ builtins.toFile "output" ( builtins.toString secondary.output ) } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ expected ( builtins.map builtins.toJSON path ) [ "output" ] ] ) }"
                                                                                                                                "${ pkgs.coreutils }/bin/ln --symbolic ${ builtins.toFile "status" ( builtins.toString secondary.status ) } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ expected ( builtins.map builtins.toJSON path ) [ "status" ] ] ) }"
                                                                                                                                "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ observed ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                                "if ${ user-environment }/bin/test-candidate > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ observed ( builtins.map builtins.toJSON path ) [ "output" ] ] ) } 2> ${ builtins.concatStringsSep "/" ( builtins.concatLists [ observed ( builtins.map builtins.toJSON path ) [ "error" ] ] ) } ; then ${ pkgs.coreutils }/bin/echo -n ${ builtins.concatStringsSep "" [ "$" "{" "?" "}" ] } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ observed ( builtins.map builtins.toJSON path ) [ "status" ] ] ) } ; else ${ pkgs.coreutils }/bin/echo -n ${ builtins.concatStringsSep "" [ "$" "{" "?" "}" ] } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ observed ( builtins.map builtins.toJSON path ) [ "status" ] ] ) } ; fi"
                                                                                                                            ]
                                                                                                                            (
                                                                                                                                let
                                                                                                                                    generator =
                                                                                                                                        index :
                                                                                                                                            let
                                                                                                                                                mount = builtins.getAttr tag ( secondary.mounts ) ;
                                                                                                                                                tag = builtins.elemAt ( builtins.attrNames primary.mounts ) index ;
                                                                                                                                                in "${ pkgs.coreutils }/bin/cp --recursive ${ builtins.concatStringsSep "" [ "$" "{" "MOUNT_" ( builtins.toString index ) "}" ] } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ observed ( builtins.map builtins.toJSON path ) [ "mount.${ builtins.toString index }" ] ] ) }" ;
                                                                                                                                    in builtins.genList generator ( builtins.length ( builtins.attrValues primary.mounts ) )
                                                                                                                            )
                                                                                                                            [
                                                                                                                                "${ pkgs.coreutils }/bin/ln --symbolic ${ candidate }/bin/candidate ${ builtins.concatStringsSep "/" ( builtins.concatLists [ test ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                            ]
                                                                                                                        ] ;
                                                                                                    null = path : value : [ ] ;
                                                                                                }
                                                                                                {
                                                                                                    list =
                                                                                                        path : list :
                                                                                                            builtins.concatLists
                                                                                                                [
                                                                                                                    [
                                                                                                                        "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ expected ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                        "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ observed ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                        "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ test ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                    ]
                                                                                                                    ( builtins.concatLists list )
                                                                                                                ] ;
                                                                                                    set =
                                                                                                        path : set :
                                                                                                            builtins.concatLists
                                                                                                                [
                                                                                                                    [
                                                                                                                        "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ expected ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                        "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ observed ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                        "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ test ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                    ]
                                                                                                                    ( builtins.concatLists ( builtins.attrValues set ) )
                                                                                                               ] ;
                                                                                                }
                                                                                                point.tests ;
                                                                        }
                                                                        {
                                                                            list =
                                                                                path : list :
                                                                                    builtins.concatLists
                                                                                        [
                                                                                            [
                                                                                                "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) ] ) }"
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
                                                                        primary.shell-scripts ;
                                                                expected = [ "$out" "expected" ] ;
                                                                observed = [ "$out" "observed" ] ;
                                                                test = [ "$out" "test" ] ;
                                                                in builtins.concatStringsSep " &&\n\t" ( builtins.concatLists [ [ "${ pkgs.coreutils }/bin/mkdir $out" ] constructors [ "${ pkgs.coreutils }/bin/echo $out" "${ pkgs.diffutils }/bin/diff --recursive $out/expected $out/observed" ] ] ) ;
                                                        name = "tests" ;
                                                        src = ./. ;
                                                    } ;
                                        } ;
                            pkgs = builtins.import nixpkgs { system = system ; } ;
                            in
                                {
                                    checks.easy =
                                        let
                                            candidate =
                                                lib
                                                    {
                                                        mounts = { "/sandbox" = "/tmp" ; } ;
                                                        shell-scripts =
                                                            {
                                                                alpha =
                                                                    ignore :
                                                                        {
                                                                            script = self + "/scripts/alpha.sh" ;
                                                                        } ;
                                                                fib =
                                                                    ignore :
                                                                        {
                                                                            script =
                                                                                pkgs.stdenv.mkDerivation
                                                                                    {
                                                                                        installPhase =
                                                                                            ''
                                                                                                ${ pkgs.coreutils }/bin/cat ${ self + "/scripts/fib.sh" } > $out
                                                                                            '' ;
                                                                                        name = "fib" ;
                                                                                        src = ./. ;
                                                                                    } ;
                                                                            environment =
                                                                                { path , self , standard-input , string } :
                                                                                    [
                                                                                        ( string "CAT" "${ pkgs.coreutils }/bin/cat" )
                                                                                        ( string "ECHO" "${ pkgs.coreutils }/bin/echo" )
                                                                                        ( self "FIB" ( self : self.fib ) )
                                                                                        ( string "WHICH" "${ pkgs.which }/bin/which" )
                                                                                    ] ;
                                                                            tests =
                                                                                [
                                                                                    (
                                                                                        ignore :
                                                                                            {
                                                                                                mounts =
                                                                                                    {
                                                                                                        "/sandbox" =
                                                                                                            {
                                                                                                                expected = self + "/mounts/xDFzfle2" ;
                                                                                                                initial = self + "/mounts/xDFzfle2" ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                output = "0" ;
                                                                                                test = "candidate 0" ;
                                                                                            }
                                                                                    )
                                                                                ] ;
                                                                        } ;
                                                                foobar =
                                                                    ignore :
                                                                        {
                                                                            script = self + "/scripts/foobar.sh" ;
                                                                            environment =
                                                                                { path , self , standard-input , string } :

                                                                                    [
                                                                                        ( string "CAT" "${ pkgs.coreutils }/bin/cat" )
                                                                                        ( string "CUT" "${ pkgs.coreutils }/bin/cut" )
                                                                                        ( string "ECHO" "${ pkgs.coreutils }/bin/echo" )
                                                                                        ( self "FOOBAR" ( self : self.foobar ) )
                                                                                        ( path "NAME" 0 )
                                                                                        ( string "SHA512SUM" "${ pkgs.coreutils }/bin/sha512sum" )
                                                                                        ( standard-input { name = "ceb56d2bcebc8e9cc485a093712de696d47b96ca866254795e566f370e2e76d92d7522558aaf4e9e7cdd6b603b527cee48a1af68a0abc1b68f2348f055346408" ; } )
                                                                                        ( string "TOKEN" "7861c7b30f4c436819c890600b78ca11e10494c9abea9cae750c26237bc70311b60bb9f8449b32832713438b36e8eaf5ec719445e6983c8799f7e193c9805a7" )
                                                                                        ( string "TR" "${ pkgs.coreutils }/bin/tr" )
                                                                                    ] ;
                                                                            tests =
                                                                                [
                                                                                    (
                                                                                        ignore :
                                                                                           {
                                                                                                error = "50885ccf7ec0a2420f1c7555e54df8512508f93002313cfd71d6de510f8a8a6c035beca3589f2a5248069e02f57535ef3231004cd8d40f8a79b28d605fb6f89b" ;
                                                                                                mounts =
                                                                                                    {
                                                                                                        "/sandbox" =
                                                                                                            {
                                                                                                                expected = self + "/mounts/RSGhGwNk" ;
                                                                                                                initial = self + "/mounts/QoqNiM1R" ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                output = "45c6ae4c0d3b624d4aa46d90b1ff7dfc996f05827014339549e01b3cb4465cde65493280935d121481c08871aac8ef4739253347e132411d2a1d5075c66bf067" ;
                                                                                                test = "candidate c64de1b7282c845986c0cf68c2063a11974e7eb0182f30a315a786c071bd253b6e97ce0afbfb774659177fdf97471f9637b07a1e5c0dff4c6c3a5dfcb05f0a50" ;
                                                                                                status = 35 ;
                                                                                            }
                                                                                    )
                                                                                    (
                                                                                        ignore :
                                                                                           {
                                                                                                error = "cda54c2ea3f3b8a7cc2ecc3fcfdbdf16f01ad317614acd60e1cdd3232dc269904e69f5dd7f7fa76309b3f277ceaa1dea931d2fdb37db5afa543421c5457993da" ;
                                                                                                mounts =
                                                                                                    {
                                                                                                        "/sandbox" =
                                                                                                            {
                                                                                                                expected = self + "/mounts/K4BODmfI" ;
                                                                                                                initial = self + "/mounts/QoqNiM1R" ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                output = "c8178d4c4118a83848b4b11279e10b0a7a9b3a322973f6893a5da5bde718d052f205ed89264afcca9adc66e0fbc03cb1ba8b35a87de734e332af0e393478abb3" ;
                                                                                                test = "${ pkgs.coreutils }/bin/echo f37938b0af93fdfe59ae7fb1d76c4aa6bc14fbbe50f37c1963216253dc5d0a4cb9d54721d52b632b4a74d2d2b461bfc11ac35e1f985cdd90d3c79fe1bfe674e9 | candidate c64de1b7282c845986c0cf68c2063a11974e7eb0182f30a315a786c071bd253b6e97ce0afbfb774659177fdf97471f9637b07a1e5c0dff4c6c3a5dfcb05f0a50" ;
                                                                                                status = 11 ;
                                                                                            }
                                                                                    )
                                                                                ] ;
                                                                        } ;
                                                            } ;
                                                    } ;
                                            in candidate.tests ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}