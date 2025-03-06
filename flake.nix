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
                                    mounts ? { } ,
                                    shell-scripts ? null
                                } :
                                    let
                                        _visitor = builtins.getAttr system visitor.lib ;
                                        primary =
                                            {
                                                default-name = if builtins.typeOf default-name == "string" then default-name else builtins.throw "default-name is not string but ${ builtins.typeOf default-name }." ;
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
                                                                                    script = script ;
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
                                                                                                                    {
                                                                                                                        self =
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
                                                                                                                        string = name : value : "--set ${ name } ${ builtins.toString value }" ;
                                                                                                                    } ;
                                                                                                                in environment injection ;
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
                                            derivation = derivation ;
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
                                                _visitor
                                                    {
                                                        lambda =
                                                            path : value :
                                                                pkgs.stdenv.mkDerivation
                                                                    {
                                                                        installPhase =
                                                                            let
                                                                                candidate =
                                                                                    pkgs.stdenv.mkDerivation
                                                                                        {
                                                                                            installPhase =
                                                                                                ''
                                                                                                    ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                                                        ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                                                        ${ pkgs.coreutils }/bin/ln \
                                                                                                            --symbolic \
                                                                                                            ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ derivation ] ( builtins.map builtins.toJSON path ) ] ) } \
                                                                                                            $out/bin/${ if builtins.length path > 0 then builtins.toString ( builtins.elemAt path ( ( builtins.length path ) - 1 ) ) else primary.default-name }
                                                                                                '' ;
                                                                                            name = "candidate" ;
                                                                                            src = ./. ;
                                                                                        } ;
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
                                                                                                                        error ? "" ,
                                                                                                                        output ? "" ,
                                                                                                                        status ? "0" ,
                                                                                                                        test
                                                                                                                    } :
                                                                                                                        {
                                                                                                                            error = error ;
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
                                                                                                                    runScript = secondary.test ;
                                                                                                                    targetPkgs = pkgs : [ candidate ] ;
                                                                                                                } ;
                                                                                                        in
                                                                                                            builtins.concatLists
                                                                                                                [
                                                                                                                    (
                                                                                                                        builtins.genList ( index : "export MOUNT_${ builtins.toString index }=$( ${ pkgs.coreutils }/bin/mktemp --directory )" ) ( builtins.length ( builtins.attrValues primary.mounts ) )
                                                                                                                    )
                                                                                                                    [
                                                                                                                        "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                        "if ${ user-environment }/bin/test-candidate > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "output.observed" ] ] ) } 2> ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "error.observed" ] ] ) } ; then ${ pkgs.coreutils }/bin/echo ${ builtins.concatStringsSep "" [ "$" "{" "?" "}" ] } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "status.observed" ] ] ) } ; else ${ pkgs.coreutils }/bin/echo ${ builtins.concatStringsSep "" [ "$" "{" "?" "}" ] } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "status.observed" ] ] ) } ; fi"
                                                                                                                        "${ pkgs.coreutils }/bin/chmod 0755 ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "output.observed" ] ] ) } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "error.observed" ] ] ) } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "error.observed" ] ] ) }"
                                                                                                                    ]
                                                                                                                    [
                                                                                                                        "${ pkgs.coreutils }/bin/echo ${ builtins.toString secondary.test } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "test" ] ] ) }"
                                                                                                                        "${ pkgs.coreutils }/bin/chmod 0444 ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "test" ] ] ) }"
                                                                                                                    ]
                                                                                                                    [
                                                                                                                        "${ pkgs.coreutils }/bin/echo ${ builtins.toString secondary.output } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "output.expected" ] ] ) }"
                                                                                                                        "${ pkgs.coreutils }/bin/chmod 0444 ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "output.expected" ] ] ) }"
                                                                                                                    ]
                                                                                                                    [
                                                                                                                        "${ pkgs.coreutils }/bin/echo ${ builtins.toString secondary.error } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "error.expected" ] ] ) }"
                                                                                                                        "${ pkgs.coreutils }/bin/chmod 0444 ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "error.expected" ] ] ) }"
                                                                                                                    ]
                                                                                                                    [
                                                                                                                        "${ pkgs.coreutils }/bin/echo ${ builtins.toString secondary.status } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "status.expected" ] ] ) }"
                                                                                                                        "${ pkgs.coreutils }/bin/chmod 0444 ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "status.expected" ] ] ) }"
                                                                                                                    ]
                                                                                                                    (
                                                                                                                        let
                                                                                                                            generator = index : "${ pkgs.coreutils }/bin/mv ${ builtins.concatStringsSep "" [ "$" "{" "MOUNT_" ( builtins.toString index ) "}" ] } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) [ "mounts.${ builtins.toString index }.observed" ] ] ) }" ;
                                                                                                                            in builtins.genList generator ( builtins.length ( builtins.attrValues primary.mounts ) )
                                                                                                                    )
                                                                                                                ] ;
                                                                                        }
                                                                                        {
                                                                                            list =
                                                                                                path : list :
                                                                                                    builtins.concatLists
                                                                                                        [
                                                                                                            [
                                                                                                                "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                            ]
                                                                                                             ( builtins.concatLists list )
                                                                                                        ] ;
                                                                                            set =
                                                                                                path : set :
                                                                                                    builtins.concatLists
                                                                                                        [
                                                                                                            [
                                                                                                                "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                            ]
                                                                                                            ( builtins.concatLists ( builtins.attrValues set ) )
                                                                                                        ] ;
                                                                                        }
                                                                                        point.tests ;
                                                                                point = value null ;
                                                                                in builtins.concatStringsSep " &&\n\t" constructors ;
                                                                        name = builtins.concatStringsSep "/" ( builtins.map builtins.toJSON path ) ;
                                                                        src = ./. ;
                                                                    } ;
                                                    }
                                                    { }
                                                    primary.shell-scripts ;
                                        } ;
                            pkgs = builtins.import nixpkgs { system = system ; } ;
                            in
                                {
                                    checks.easy =
                                        pkgs.stdenv.mkDerivation
                                            {
                                                installPhase =
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
                                                                                        script = self + "/scripts/fib.sh" ;
                                                                                        environment =
                                                                                            { self , string } :
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
                                                                                                            test = "fib 0" ;
                                                                                                            output = "0" ;
                                                                                                        }
                                                                                                )
                                                                                            ] ;
                                                                                    } ;
                                                                            foobar =
                                                                                ignore :
                                                                                    {
                                                                                        script = self + "/scripts/foobar.sh" ;
                                                                                        environment =
                                                                                            { self , string } :
                                                                                                [
                                                                                                    ( string "ECHO" "${ pkgs.coreutils }/bin/echo" )
                                                                                                    ( string "STANDARD_ERROR" "b2c7c67b1451b4e2b850c29eacbe2ce6f3a9a63456e30e2c43577e4be49699c6631610527464c4b54f76257a6b396893bf1b991626c6875c159861e385905820" )
                                                                                                    ( string "STANDARD_OUTPUT" "e8c856e1819a2403d5b210a8abebcb6c75abdfd4e5fd0d93669d4b80fe0bfda8c70cff03ba4f47564506bd5c21c0bb9710ff6f270aa330721ee96707887e50a5" )
                                                                                                    ( string "STATUS" 113 )
                                                                                                    ( string "TOKEN" "7861c7b30f4c436819c890600b78ca11e10494c9abea9cae750c26237bc70311b60bb9f8449b32832713438b36e8eaf5ec719445e6983c8799f7e193c9805a7" )
                                                                                                ] ;
                                                                                        tests =
                                                                                            [
                                                                                                (
                                                                                                    ignore :
                                                                                                       {
                                                                                                            error = "b2c7c67b1451b4e2b850c29eacbe2ce6f3a9a63456e30e2c43577e4be49699c6631610527464c4b54f76257a6b396893bf1b991626c6875c159861e385905820" ;
                                                                                                            output = "e8c856e1819a2403d5b210a8abebcb6c75abdfd4e5fd0d93669d4b80fe0bfda8c70cff03ba4f47564506bd5c21c0bb9710ff6f270aa330721ee96707887e50a5" ;
                                                                                                            test = "foobar c64de1b7282c845986c0cf68c2063a11974e7eb0182f30a315a786c071bd253b6e97ce0afbfb774659177fdf97471f9637b07a1e5c0dff4c6c3a5dfcb05f0a50" ;
                                                                                                            status = 113 ;
                                                                                                        }
                                                                                                )
                                                                                            ] ;
                                                                                    } ;
                                                                        } ;
                                                                } ;
                                                        in
                                                            ''
                                                                ${ pkgs.coreutils }/bin/touch $out &&
                                                                    ${ pkgs.coreutils }/bin/echo ${ candidate.derivation } &&
                                                                    ${ pkgs.coreutils }/bin/echo ${ candidate.shell-scripts.fib } &&
                                                                    ${ pkgs.coreutils }/bin/echo ${ candidate.tests.foobar } &&
                                                                    exit 64
                                                            '' ;
                                                name = "easy" ;
                                                src = ./. ;
                                            } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}