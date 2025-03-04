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
                                    shell-scripts ? null ,
                                    default-name ? "script"
                                } :
                                    let
                                        _visitor = builtins.getAttr system visitor.lib ;
                                        dependencies =
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
                                                                                                                                            dependencies ;
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
                                                                    dependencies ;
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
                                                                        else default-name ;
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
                                                    dependencies ;
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
                                                                                                        identity =
                                                                                                            {
                                                                                                                name ? if builtins.length path > 0 then builtins.toString ( builtins.elemAt path ( ( builtins.length path ) - 1 ) ) else "test" ,
                                                                                                                prepare ? null ,
                                                                                                                pipe ? null ,
                                                                                                                arguments ? null ,
                                                                                                                file ? null ,
                                                                                                                init ? null ,
                                                                                                                expected-standard-output ? null ,
                                                                                                                expected-standard-error ? null ,
                                                                                                                expected-status ? null ,
                                                                                                                expected-output ? null
                                                                                                                } :
                                                                                                                    {
                                                                                                                        name = name ;
                                                                                                                        prepare = prepare ;
                                                                                                                        pipe = pipe ;
                                                                                                                        arguments = arguments ;
                                                                                                                        file = file ;
                                                                                                                        init = init ;
                                                                                                                        expected-standard-output = expected-standard-output ;
                                                                                                                        expected-standard-error = expected-standard-error ;
                                                                                                                        expected-status = expected-status ;
                                                                                                                        expected-output = expected-output ;
                                                                                                                    } ;
                                                                                                        point = identity ( value null ) ;
                                                                                                        root = builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) ;
                                                                                                        test =
                                                                                                            let
                                                                                                                with-arguments = if builtins.typeOf point.arguments == "null" then "/candidate" else "/candidate ${ point.arguments }" ;
                                                                                                                in with-arguments ;
                                                                                                        user-environment =
                                                                                                            pkgs.buildFHSUserEnv
                                                                                                                {
                                                                                                                    extraBwrapArgs = [ "--ro-bind ${ candidate } /candidate" ] ;
                                                                                                                    name = point.name ;
                                                                                                                    runScript = test ;
                                                                                                                } ;
                                                                                                        in
                                                                                                            builtins.concatLists
                                                                                                            [
                                                                                                                [
                                                                                                                    "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                                    "${ pkgs.coreutils }/bin/echo ${ pkgs.writeShellScript "test" ( builtins.toFile "test" test ) } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }/test.sh"
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
                                                    dependencies ;
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
                                                                                                ( ignore : { } )
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