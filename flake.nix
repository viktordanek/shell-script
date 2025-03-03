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
                                    shell-scripts ? null
                                } :
                                    let
                                        _visitor = builtins.getAttr system visitor.lib ;
                                        derivation =
                                            pkgs.stdenv.mkDerivation
                                                {
                                                    installPhase =
                                                        _visitor
                                                            {
                                                                lambda =
                                                                    path : value :
                                                                        "${ pkgs.coreutils }/bin/ln --symbolic ${ true } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }
                                                                list =
                                                                    path : list :
                                                                        builtins.concatLists
                                                                            [
                                                                                [
                                                                                    ''
                                                                                        ${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }
                                                                                    ''
                                                                                ]
                                                                                ( builtins.concatLists list )
                                                                            ] ;
                                                                set =
                                                                    path : set :
                                                                        builtins.concatLists
                                                                            [
                                                                                [
                                                                                    ''
                                                                                        ${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }
                                                                                    ''
                                                                                ]
                                                                            ] ;
                                                            } ;
                                                    name = "shell-scripts" ;
                                                    src = ./. ;
                                                } ;
                                        dependencies =
                                            _visitor
                                                {
                                                    lambda =
                                                        path : value :
                                                            let
                                                                identity =
                                                                    { image ? { } , tests ? [ ] } :
                                                                        {
                                                                            image = image ;
                                                                            tests = tests ;
                                                                        } ;
                                                                in ignore : value ignore ;
                                                }
                                                { }
                                                shell-scripts ;
                                        tests = null ;
                                    in
                                        {
                                            shell-scripts =
                                                _visitor
                                                    {
                                                        lambda =
                                                            path : value :
                                                                let
                                                                    point = value null ;
                                                                    in pkgs.buildFHSUserEnv point.image ;
                                                    }
                                                    { }
                                                    dependencies ;
                                            tests = tests ;
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
                                                                        (
                                                                            ignore :
                                                                                {
                                                                                    image =
                                                                                        {
                                                                                            name = "foobar" ;
                                                                                            targetPkgs = pkgs : [ pkgs.coreutils ] ;
                                                                                            runScript = "echo Hello World" ;
                                                                                        } ;
                                                                                }
                                                                        ) ;
                                                                } ;
                                                        in
                                                            ''
                                                                ${ pkgs.coreutils }/bin/touch $out &&
                                                                    ${ pkgs.coreutils }/bin/echo ${ candidate.shell-scripts } &&
                                                                    exit 64
                                                            '' ;
                                                name = "easy" ;
                                                src = ./. ;
                                            } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}