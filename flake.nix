{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    {
                        config-identity ? x : x ,
                        lib-identity ? x : x ,
                        pkgs-identity ? x : x
                    } :
                        let
                            implementation =
                                { pkgs , ... } :
                                    let
                                        _config = config-identity config ;
                                        _lib = lib-identity lib ;
                                        _pkgs = pkgs-identity pkgs ;
                                        in
                                            {
                                                options.node-fetch =
                                                    _lib.mkOption
                                                        {
                                                            default =
                                                                package :
                                                                    _pkgs.writeShellApplication
                                                                        {
                                                                            name = "fetch" ;
                                                                            runtimeInputs =
                                                                                [
                                                                                    _pkgs.coreutils
                                                                                    _pkgs.git
                                                                                    _pkgs.nodejs_20
                                                                                    (
                                                                                        _pkgs.writeShellApplication
                                                                                            {
                                                                                                name = "explode" ;
                                                                                                runtimeInputs =
                                                                                                    [
                                                                                                        _pkgs.coreutils
                                                                                                        _pkgs.git
                                                                                                        ( _config.failure { } )
                                                                                                    ] ;
                                                                                                text =
                                                                                                    ''
                                                                                                        RELATIVE_INPUT_FILE="$1"
                                                                                                        ABSOLUTE_INPUT_FILE="$( realpath "$RELATIVE_INPUT_FILE" )" || failure 7861779372817123
                                                                                                        TAG="${ "$" }{RELATIVE_INPUT_FILE#node_modules/}"
                                                                                                        HASH="$( echo "$TAG" | sha512sum | cut --characters 1-128 )" || failure 3652604998111458
                                                                                                        RELATIVE_OUTPUT_FILE="node_modules.exploded/$HASH"
                                                                                                        PERMISSIONS="$( stat --printf %a "$ABSOLUTE_INPUT_FILE" )" || failure 9035064744130892
                                                                                                        TYPE="$( stat --printf %F "$ABSOLUTE_INPUT_FILE" )" || failure 9216061067032392
                                                                                                        if [[ -d "$RELATIVE_OUTPUT_FILE" ]]
                                                                                                        then
                                                                                                            failure 0701446510561736 "$HASH" "$PERMISSIONS" "$TAG" "$TYPE"
                                                                                                        else
                                                                                                            mkdir --parents "$RELATIVE_OUTPUT_FILE"
                                                                                                        fi
                                                                                                        cd "$RELATIVE_OUTPUT_FILE"
                                                                                                        jq \
                                                                                                            --null-input \
                                                                                                            --arg PERMISSIONS "$PERMISSIONS" \
                                                                                                            --arg TAG "$TAG" \
                                                                                                            --arg TYPE "$TYPE" \
                                                                                                            '{
                                                                                                                "permissions" : $PERMISSIONS ,
                                                                                                                "tag" : $TAG ,
                                                                                                                "type" : $TYPE
                                                                                                            }' > metadata.json
                                                                                                        git add metadata.json
                                                                                                        if [[ -d "$ABSOLUTE_INPUT_FILE" ]]
                                                                                                        then
                                                                                                            :
                                                                                                        elif [[ -f "$ABSOLUTE_INPUT_FILE" ]]
                                                                                                        then
                                                                                                            mkdir parts
                                                                                                            cd parts
                                                                                                            split --bytes 1M "$ABSOLUTE_INPUT_FILE"
                                                                                                        else
                                                                                                            failure 9059723240083957 "$ABSOLUTE_INPUT_FILE" "$PERMISSIONS" "$TAG" "$TYPE"
                                                                                                        fi
                                                                                                        git add .
                                                                                                    '' ;
                                                                                            }
                                                                                    )
                                                                                ] ;
                                                                            text =
                                                                                ''
                                                                                    MESSAGE="$1"
                                                                                    cat ${ builtins.toFile "package.json" ( builtins.toJSON package ) } > "package.json"
                                                                                    git add package.json
                                                                                    git rm -r --ignore-unmatch node_modules.exploded
                                                                                    npm install
                                                                                    find node_modules -exec explode {} \;
                                                                                    git clean -fd
                                                                                    git commit -m "$MESSAGE" --allow-empty --allow-empty-message
                                                                                '' ;
                                                                        } ;
                                                            type = _lib.types.functionTo _lib.types.package ;
                                                        } ;
                                            } ;
                            in
                                {
                                    implementation = implementation ;
                                    check = null ;
                                } ;
            } ;
}