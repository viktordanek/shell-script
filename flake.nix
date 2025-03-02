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
                                        #dependencies =
                                        #    visitor.lib
                                        #        {
                                        #            lambda = path : value : value ;
                                        #            null = path : value : { ... } : { } ;
                                        #        }
                                        #        { }
                                        #        shell-scripts ;
                                        shell-scripts_ =
                                            _visitor
                                                {
                                                    lambda =
                                                        path : value :
                                                            let
                                                                identity =
                                                                    { environment ? x : [ ] , executable , tests ? [ ] } :
                                                                        {
                                                                            environment = environment ;
                                                                            executable = executable ;
                                                                            tests = tests ;
                                                                        } ;
                                                                point = identity ( value shell-script ) ;
                                                                shell-script =
                                                                    { environment ? x : [ ] , executable , tests ? [ ] } :
                                                                        ''
                                                                            ${ executable }
                                                                        '' ;
                                                                in point.executable ;
                                                }
                                                { } ;
                                        tests = null ;
                                    in
                                        {
                                            shell-scripts = shell-scripts_ ;
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
                                                                    shell-scripts = ( shell-script : shell-script { executable = "foobar" ; } ) ;
                                                                } ;
                                                        in
                                                            ''
                                                                ${ pkgs.coreutils }/bin/touch $out &&
                                                                    exit 64
                                                            '' ;
                                                name = "easy" ;
                                                src = ./. ;
                                            } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}