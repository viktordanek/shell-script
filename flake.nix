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
                                    environment ? x : [ ] ,
                                    extensions ? [ ] ,
                                    name ,
                                    script ,
                                    tests ? null
                                } :
                                    let
                                        primary =
                                            {
                                                environment =
                                                    if builtins.typeOf environment == "lambda" then
                                                        if builtins.typeOf environment primary.extensions == "list" then
                                                            builtins.map ( e : if builtins.typeOf e == "string" then e else builtins.throw "environment is not string but ${ builtins.typeOf e }." ) environment primary.extensions
                                                        else builtins.throw "environments is not list but ${ builtins.typeOf ( environment primary.extension ) }."
                                                    else builtins.throw "environments is not lambda but ${ builtins.typeOf environment }." ;
                                                extensions =
                                                    if builtins.typeOf extensions == "set" then
                                                        builtins.mapAttr ( name : value : if builtins.typeOf value == "lambda" then value else builtins.throw "extension is not lambda but ${ builtins.typeOf value }." ) extensions
                                                    else builtins.throw "extensions is not set but ${ builtins.typeOf extensions }." ;
                                                name =
                                                    if builtins.typeOf name == "string" then
                                                        if pkgs.lib.strings.match "^[a-zA-Z_][a-zA-Z0-9_-]*$" name != null then name
                                                        else builtins.throw "the name (${ name }) is not suitable for a bash script."
                                                    else builtins.throw "name is not string but ${ builtins.typeOf name }." ;
                                                script =
                                                    if builtins.typeOf script == "string" then
                                                        if builtins.pathExists script then script
                                                        else builtins.throw "there is no path for ${ script }."
                                                    else builtins.throw "script is not string but ${ builtins.typeOf script }." ;
                                                tests =
                                                    if builtins.typeOf tests == "null" then tests
                                                    else if builtins.typeOf tests == "list" then tests
                                                    else if builtins.typeOf tests == "set" then tests
                                                    else builtins.throw "tests is not null, list, set but ${ builtins.typeOf tests }." ;
                                            } ;
                                        shell-script =
                                            name :
                                                pkgs.stdenv.mkDerivation
                                                    {
                                                        installPhase =
                                                            let
                                                                source =
                                                                    pkgs.stdenv.mkDerivation
                                                                        {
                                                                            installPhase = "${ pkgs.coreutils }/bin/install -D --mode 555 ${ script } $out" ;
                                                                            name = "source" ;
                                                                            src = ./. ;
                                                                        } ;
                                                                in
                                                                    ''
                                                                        ${ pkgs.coreutils }/bin/mkdir $out &&
                                                                            ${ pkgs.coreutils }/bin/mkdir $out/bin &&
                                                                            makeWrapper ${ source } $out/bin/${ name } ${ builtins.concatStringsSep " " ( environment extensions ) }
                                                                    '' ;
                                                        name = name ;
                                                        nativeBuildInputs = [ pkgs.makeWrapper ] ;
                                                        src = ./. ;
                                                    } ;
                                        in
                                            {
                                                shell-script = "${ shell-script primary.name }/bin/${ primary.name }" ;
                                                tests =
                                                    pkgs.stdenv.mkDerivation
                                                        {
                                                            installPhase =
                                                                let
                                                                    _visitor = builtins.getAttr system visitor.lib ;
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
                                                                                                            arguments ? [ ] ,
                                                                                                            file ? null ,
                                                                                                            mounts ? { } ,
                                                                                                            pipe ? null ,
                                                                                                            standard-error ? "" ,
                                                                                                            standard-output ? "" ,
                                                                                                            status ? 0
                                                                                                        } :
                                                                                                            {
                                                                                                                arguments =
                                                                                                                    if builtins.typeOf arguments == "list" then
                                                                                                                        builtins.map ( a : if builtins.typeOf a == "string" then a else builtins.throw "argument is not string but ${ builtins.typeOf a }." ) arguments
                                                                                                                    else builtins.throw "arguments is not list but ${ builtins.typeOf arguments }." ;
                                                                                                                file =
                                                                                                                    if builtins.typeOf file == "null" then [ ]
                                                                                                                    else if builtins.typeOf file == "string" then
                                                                                                                        let
                                                                                                                            eval = builtins.toFile "file" file ;
                                                                                                                            in if eval.success == true then [ "<" eval.value ] else builtins.throw "file (${ file }) is not a string that can be filed"
                                                                                                                    else builtins.throw "file is not null, string but ${ builtins.typeOf file }." ;
                                                                                                                mounts =
                                                                                                                    if builtins.typeOf mounts == "set" then
                                                                                                                        let
                                                                                                                            mapper =
                                                                                                                                name : { expected , initial ? null , permissions ? null } :
                                                                                                                                    {
                                                                                                                                        initial =
                                                                                                                                            if builtins.typeOf initial == "null" then initial
                                                                                                                                            else if builtins.typeOf initial == "string" then
                                                                                                                                                if builtins.pathExists initial then initial
                                                                                                                                                else builtins.throw "there is no path for ${ initial }."
                                                                                                                                            else builtins.throw "initial is not null, string but ${ builtins.typeOf initial }." ;
                                                                                                                                        expected =
                                                                                                                                            if builtins.typeOf expected == "string" then
                                                                                                                                                if builtins.pathExists expected then expected
                                                                                                                                                else builtins.throw "there is no path for ${ expected }."
                                                                                                                                            else builtins.throw "expected is not string but ${ builtins.typeOf expected }." ;
                                                                                                                                        permissions =
                                                                                                                                            _visitor
                                                                                                                                                {
                                                                                                                                                    int =
                                                                                                                                                        path : value :
                                                                                                                                                            [
                                                                                                                                                                (
                                                                                                                                                                    "chmod ${ builtins.toString value } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "/build" "mounts" name ] ( builtins.map builtins.toString path ) ] ) }"
                                                                                                                                                                )
                                                                                                                                                            ] ;
                                                                                                                                                }
                                                                                                                                                {
                                                                                                                                                    list = path : list : builtins.concatLists list ;
                                                                                                                                                    set = path : set : builtins.concatLists ( builtins.attrValues set ) ;
                                                                                                                                                }
                                                                                                                                                permissions ;
                                                                                                                                    } ;
                                                                                                                            in builtins.mapAttrs mapper mounts
                                                                                                                    else builtins.throw "mounts is not set but ${ builtins.typeOf mounts }." ;
                                                                                                                pipe =
                                                                                                                    if builtins.typeOf pipe == "null" then [ ]
                                                                                                                    else if builtins.typeOf pipe == "string" then
                                                                                                                        let
                                                                                                                            eval = builtins.toFile "pipe" pipe ;
                                                                                                                            in if eval.success == true then [ "cat" eval.value "|" ] else builtins.throw "pipe (${ pipe }) is not a string that be filed."
                                                                                                                    else builtins.throw "pipe is not null, string but ${ builtins.typeOf pipe }." ;
                                                                                                                standard-error =
                                                                                                                    if builtins.typeOf standard-error == "string" then standard-error
                                                                                                                    else builtins.throw "standard-error is not string but ${ builtins.typeOf standard-error }." ;
                                                                                                                standard-output =
                                                                                                                    if builtins.typeOf standard-output == "string" then standard-output
                                                                                                                    else builtins.throw "standard-output is not string but ${ builtins.typeOf standard-output }." ;
                                                                                                                status =
                                                                                                                    if builtins.typeOf status == "int" then builtins.toString status
                                                                                                                    else builtins.throw "status is not int but ${ builtins.typeOf status }." ;
                                                                                                            } ;
                                                                                                in identity ( value null ) ;
                                                                                            in
                                                                                                builtins.concatLists
                                                                                                    [
                                                                                                        [
                                                                                                            "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                        ]
                                                                                                        (
                                                                                                            if builtins.length ( builtins.attrNames secondary.mounts ) == 0 then [ ]
                                                                                                            else
                                                                                                                builtins.concatLists
                                                                                                                    [
                                                                                                                        [
                                                                                                                            "${ pkgs.coreutils }/bin/mkdir /build/mounts"
                                                                                                                            "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) [ "mounts" ] ] ) }"
                                                                                                                        ]
                                                                                                                        (
                                                                                                                            let
                                                                                                                                mapper =
                                                                                                                                    name : { expected , initial , permissions } :
                                                                                                                                        [
                                                                                                                                            "${ pkgs.coreutils }/bin/mkdir /build/mounts/${ name }"
                                                                                                                                            "${ pkgs.coreutils }/bin/cp --recursive --preserve=mode ${ initial }/* /build/mounts/${ name }"
                                                                                                                                            "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) [ "mounts" name ] ] ) }"
                                                                                                                                            "${ pkgs.coreutils }/bin/cp --recursive --preserve=mode ${ expected }/* ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) [ "mounts" name ] ] ) }"
                                                                                                                                        ] ;
                                                                                                                                in builtins.concatLists ( builtins.attrValues ( builtins.mapAttrs mapper secondary.mounts ) )
                                                                                                                        )
                                                                                                                    ]
                                                                                                        )
                                                                                                        [
                                                                                                            "${ pkgs.coreutils }/bin/echo ${ secondary.standard-output } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) [ "standard-output" ] ] ) }"
                                                                                                            "${ pkgs.coreutils }/bin/echo ${ secondary.standard-error } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) [ "standard-error" ] ] ) }"
                                                                                                            "${ pkgs.coreutils }/bin/echo ${ secondary.status } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "expected" ] ( builtins.map builtins.toJSON path ) [ "status" ] ] ) }"
                                                                                                        ]
                                                                                                        [
                                                                                                            "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                            (
                                                                                                                let
                                                                                                                    file = builtins.toFile "file" ( builtins.concatStringsSep " &&\n\t" ( builtins.concatLists [ permissions [ test ] ] ) ) ;
                                                                                                                    permissions = builtins.concatLists ( builtins.attrValues ( builtins.mapAttrs ( name : { expected , initial , permissions } : permissions ) secondary.mounts ) ) ;
                                                                                                                    test = builtins.concatStringsSep " " ( builtins.concatLists [ secondary.pipe [ "candidate" ] secondary.arguments secondary.file ] ) ;
                                                                                                                    in
                                                                                                                        "${ pkgs.coreutils }/bin/cat ${ file } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) [ "script" ] ] ) }"
                                                                                                            )
                                                                                                            "${ pkgs.coreutils }/bin/chmod 0555 ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) [ "script" ] ] ) }"
                                                                                                            "makeWrapper ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) [ "script" ] ] ) } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) [ "binary" ] ] ) } --set PATH ${ pkgs.coreutils }/bin:${ shell-script "candidate" }/bin"
                                                                                                            "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) ] ) }"
                                                                                                            (
                                                                                                                let
                                                                                                                    user-environment =
                                                                                                                        pkgs.buildFHSUserEnv
                                                                                                                            {
                                                                                                                                extraBwrapArgs =
                                                                                                                                    let
                                                                                                                                        mapper = value : "--bind /build/mounts/${ value } /${ builtins.trace value value }" ;
                                                                                                                                        in builtins.map mapper ( builtins.attrNames secondary.mounts ) ;
                                                                                                                                name = "observation" ;
                                                                                                                                runScript = "${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "test" ] ( builtins.map builtins.toJSON path ) [ "binary" ] ] ) }" ;
                                                                                                                            } ;
                                                                                                                    in "if ${ user-environment }/bin/observation > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) [ "standard-output" ] ] ) } 2> ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) [ "standard-error" ] ] ) } ; then ${ pkgs.coreutils }/bin/echo ${ builtins.concatStringsSep "" [ "$" "{" "?" "}" ] } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) [ "status" ] ] ) } ; else ${ pkgs.coreutils }/bin/echo ${ builtins.concatStringsSep "" [ "$" "{" "?" "}" ] } > ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) [ "status" ] ] ) } ; fi"
                                                                                                            )
                                                                                                        ]
                                                                                                        (
                                                                                                            if builtins.length ( builtins.attrNames secondary.mounts ) == 0 then [ ]
                                                                                                            else
                                                                                                                builtins.concatLists
                                                                                                                    [
                                                                                                                        [
                                                                                                                            "${ pkgs.coreutils }/bin/mkdir ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) [ "mounts" ] ] ) }"
                                                                                                                        ]
                                                                                                                        (
                                                                                                                            let
                                                                                                                                mapper =
                                                                                                                                    name :
                                                                                                                                        "${ pkgs.coreutils }/bin/cp --recursive /build/mounts/${ name } ${ builtins.concatStringsSep "/" ( builtins.concatLists [ [ "$out" "observed" ] ( builtins.map builtins.toJSON path ) [ "mounts" name ] ] ) }" ;
                                                                                                                                in builtins.map mapper ( builtins.attrNames secondary.mounts )
                                                                                                                        )
                                                                                                                    ]
                                                                                                        )
                                                                                                    ] ;
                                                                                null = path : value : [ ] ;
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
                                                                            tests ;
                                                                    root =
                                                                        builtins.concatLists
                                                                            [
                                                                                [
                                                                                    "${ pkgs.coreutils }/bin/mkdir $out"
                                                                                ]
                                                                                constructors
                                                                                [
                                                                                    "${ pkgs.diffutils }/bin/diff --recursive $out/expected $out/observed"
                                                                                ]
                                                                            ] ;
                                                                    in builtins.concatStringsSep " &&\n\t" root ;
                                                            name = "tests" ;
                                                            nativeBuildInputs = [ pkgs.makeWrapper ] ;
                                                            src = ./. ;
                                                        } ;
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
                                                                shell-script =
                                                                    lib
                                                                        {
                                                                            environment =
                                                                                { string } :
                                                                                    [
                                                                                        ( string "CAT" "${ pkgs.coreutils }/bin/cat" )
                                                                                        ( string "CHMOD" "${ pkgs.coreutils }/bin/chmod" )
                                                                                        ( string "ECHO" "${ pkgs.coreutils }/bin/echo" )
                                                                                    ] ;
                                                                            extensions =
                                                                                {
                                                                                    string = name : value : "--set ${ name } ${ value }" ;
                                                                                } ;
                                                                            name = "foobar" ;
                                                                            script = self + "/scripts/foobar.sh" ;
                                                                            tests =
                                                                                {
                                                                                    null =
                                                                                        ignore :
                                                                                            {
                                                                                                mounts =
                                                                                                    {
                                                                                                        singleton =
                                                                                                            {
                                                                                                                expected = self + "/mounts/expected" ;
                                                                                                                initial = self + "/mounts/initial" ;
                                                                                                                permissions =
                                                                                                                    {
                                                                                                                        file = 777 ;
                                                                                                                    } ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                                standard-error = "standard-error 6641672962c2fdb4d4a3686c119c74dd89164f7e489a75008b514b668347b004de670b3e4ad7d5010599a103743c7febb4d767901e78298933a42d16642c7060" ;
                                                                                                standard-output = "standard-output 6641672962c2fdb4d4a3686c119c74dd89164f7e489a75008b514b668347b004de670b3e4ad7d5010599a103743c7febb4d767901e78298933a42d16642c7060";
                                                                                                status = 96 ;
                                                                                            } ;
                                                                                } ;
                                                                        } ;
                                                                in
                                                                    ''
                                                                        ${ pkgs.coreutils }/bin/touch $out &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ shell-script.shell-script } &&
                                                                            ${ pkgs.coreutils }/bin/echo ${ shell-script.tests } &&
                                                                            exit 55
                                                                    '' ;
                                                        name = "foobar" ;
                                                        src = ./. ;
                                                    } ;
                                        } ;
                                    lib = lib ;
                                } ;
                in flake-utils.lib.eachDefaultSystem fun ;
}