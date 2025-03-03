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
                                                                                [
                                                                                    (
                                                                                        let
                                                                                            identity = { runScript , targetPkgs } :
                                                                                                {
                                                                                                    runScript = runScript ;
                                                                                                    targetPkgs = targetPkgs ;
                                                                                                } ;
                                                                                            image =
                                                                                                {
                                                                                                    name = if builtins.length path == 0 then default-name else builtins.elemAt path ( ( builtins.length path ) - 1 ) ;
                                                                                                    # runScript = point.runScript ;
                                                                                                    targetPkgs = point.targetPkgs ;
                                                                                                } ;
                                                                                            point = identity ( value null ) ;
                                                                                            in
                                                                                                "makeWrapper ${ pkgs.buildFHSUserEnv image }/bin/${ image.name } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                    )
                                                                                ] ;
                                                                    }
                                                                    {
                                                                        list =
                                                                            path : list :
                                                                                builtins.concatLists
                                                                                    [
                                                                                        [
                                                                                            ''${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }''
                                                                                        ]
                                                                                        ( builtins.concatLists list )
                                                                                    ] ;
                                                                        set =
                                                                            path : set :
                                                                                builtins.concatLists
                                                                                    [
                                                                                        [
                                                                                            ''${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" ] ( builtins.map builtins.toJSON path ) ] ) }''
                                                                                        ]
                                                                                        ( builtins.concatLists ( builtins.attrValues set ) )
                                                                                    ] ;
                                                                    }
                                                                    dependencies ;
                                                            in builtins.concatStringsSep "&&\n\t" constructors ;
                                                    name = "shell-scripts" ;
                                                    nativeBuildInputs = [ pkgs.makeWrapper ] ;
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
                                                        lambda = path : value : builtins.concatStringsSep "/" ( builtins.concatLists [ [ derivation ] ( builtins.map builtins.toJSON path ) ] ) ;
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
                                                                        {
                                                                            fib =
                                                                                let
                                                                                    fib =
                                                                                        pkgs.writeShellScriptBin
                                                                                            "fib"
                                                                                            ''
                                                                                                if [ ${ builtins.concatStringsSep "" [ "$" "{" "1" "}" ] } -lt 3 ]
                                                                                                then
                                                                                                    echo ${ builtins.concatStringsSep "" [ "$" "{" "1" "}" ] }
                                                                                                else
                                                                                                    echo $(( $( fib $(( ${ builtins.concatStringsSep "" [ "$" "{" "1" "}" ] } - 2 )) ) * $( fib $(( ${ builtins.concatStringsSep "" [ "$" "{" "1" "}" ] } - 1 )) ) ))
                                                                                                fi
                                                                                            '' ;
                                                                                    self = pkgs.writeShellScriptBin "self" "fib 1" ;
                                                                                    in
                                                                                        ignore :
                                                                                            {
                                                                                                targetPkgs = pkgs : [ pkgs.coreutils fib self pkgs.which ] ;
                                                                                                runScript = "self" ;
                                                                                            } ;
                                                                        } ;
                                                                } ;
                                                        in
                                                            ''
                                                                ${ pkgs.coreutils }/bin/touch $out &&
                                                                    ${ pkgs.coreutils }/bin/echo ${ candidate.shell-scripts.fib } &&
                                                                    exit 64
                                                            '' ;
                                                name = "easy" ;
                                                src = ./. ;
                                            } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}