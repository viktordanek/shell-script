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
                                    mounts ? [ ] ,
                                    shell-scripts ? null
                                } :
                                    let
                                        _visitor = builtins.getAttr system visitor.lib ;
                                        primary =
                                            {
                                                default-name = if builtins.typeOf default-name == "string" then default-name else builtins.throw "default-name is not string but ${ builtins.typeOf default-name }." ;
                                                mounts =
                                                    if builtins.typeOf mounts == "list" then
                                                        let
                                                            mapper =
                                                                { host , sandbox , test } :
                                                                    {
                                                                        host = if builtins.typeOf host == "string" then host else builtins.throw "host is not string but ${ builtins.typeOf host }." ;
                                                                        sandbox = if builtins.typeOf sandbox == "string" then sandbox else builtins.throw "sandbox is not string but ${ builtins.typeOf sandbox }." ;
                                                                        test = if builtins.typeOf test == "string" then test else builtins.throw "test is not string but ${ builtins.typeOf test }." ;
                                                                    } ;
                                                                in builtins.map mapper mounts
                                                    else builtins.throw "mounts is not list but ${ builtins.typeOf mounts }." ;
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
                                                                                                        ${ pkgs.coreutils }/bin/cat ${ point.script } > $out &&
                                                                                                            ${ pkgs.coreutils }/bin/chmod 0555 $out
                                                                                                    '' ;
                                                                                                name = builtins.concatStringsSep "/" ( builtins.map builtins.toJSON path ) ;
                                                                                                src = ./. ;
                                                                                            } ;
                                                                                    point =
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
                                                                                                        script = script ;
                                                                                                    } ;
                                                                                            in identity ( value null ) ;
                                                                                    in
                                                                                        [
                                                                                            "makeWrapper ${ derivation } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] path ] ) } ${ builtins.concatStringsSep " " point.environment }"
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
                                                                                extraBwrapArgs = [ "--ro-bind ${ derivation } /shell-scripts" ] ;
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
                                                                                candidate = builtins.concatStringsSep "/" ( builtins.concatLists [ [ derivation ] ( builtins.map builtins.toJSON path ) ] ) ;
                                                                                constructors =
                                                                                    _visitor
                                                                                        {
                                                                                            lambda =
                                                                                                path : value :
                                                                                                    let
                                                                                                        point = value null ;
                                                                                                        user-environment =
                                                                                                            pkgs.buildFHSUserEnv
                                                                                                                {
                                                                                                                    name = "test-candidate" ;
                                                                                                                    runScript = point.test ;
                                                                                                                } ;
                                                                                                        in
                                                                                                            builtins.concatLists
                                                                                                                [
                                                                                                                    ### FIND ME
                                                                                                                    [
                                                                                                                        "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                        "if ! ${ user-environment }/bin/test-candidate > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }/standard-output 2> ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }/standard-error ; then ${ pkgs.coreutils }/bin/echo ${ builtins.concatStringsSep "" [ "$" "{" "?" "}" ] } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }/status ; fi"
                                                                                                                    ]
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
                                                                                                ] ;
                                                                                        tests =
                                                                                            [
                                                                                                (
                                                                                                    ignore :
                                                                                                        {
                                                                                                            test = "fib 0" ;
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
                                                                    ${ pkgs.coreutils }/bin/echo ${ candidate.tests.fib } &&
                                                                    exit 64
                                                            '' ;
                                                name = "easy" ;
                                                src = ./. ;
                                            } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}