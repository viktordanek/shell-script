Project Name

This is a NixOS Flake that sets up a shell script environment with optional extensions and tests. It provides a structured way to wire up a shell script and execute associated tests in a reproducible manner.

Inputs

The flake takes the following parameters:

1. environment (optional) – specify environment variables
2. extensions (optional) - functions used to specify environment variables
3. name (required) – The name of the shell script.
4. script (required) – The shell script to be wrapped.
5. tests (optional) – Test cases that validate the script execution.

Outputs

The flake generates the following outputs:

1. shell-script – The provided script, properly wrapped with the specified dependencies.  The flake will always generate the wrapped script even if all the tests fail.

2. tests – A derivation the includes all the tests, the observed values, and the expected values.  Since the final step of building this derivation is comparing expected to observed, if there is any deviation this derivation will fail to build and this failure would indicate that one or more tests failed.

Usage
1. Adding it to Inputs:  To use this flake, add it as an input in your flake.nix:

```
{
    inputs.shell-script.url = "github:viktordanek/shell-script";
}
```

2. Adding it to the Parameters of Outputs:  Reference the flake in the outputs function:

```
outputs = { shell-script , ... }:
    {
        
    }
```

4. Create an instance of the library
 
```
shell-script = builtins.getAttr system visitor.lib
```

5.  Create a shell--script isntance

```
foobar = shell-script { name = "foobar" ; script = "/path/to/foobar.sh" ;}
```

4. Use the shell-script

```
foobar.shell-script
```

This is a convenient way to refer to the foobar script.

5. Run the tests in the checks attribute of a nix flake

```
checks.foobar = foobar.tests ;
```

If all the tests pass this will not do too much, but if any of the tests fail the derivation will fail.  This will cause the checks to fail.  The output will be useful to diagnosing the problem.


## License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

This means that you are free to **use, modify, and distribute** this software, provided that:
- Any modified versions must also be licensed under the **AGPL-3.0**.
- If the software is used to provide a network service, users must be given access to the complete source code of the modified version.
- There is **NO WARRANTY**—the software is provided **"as is"** without any guarantees.

For more details, see the full license text in the [LICENSE](./LICENSE) file or visit:  
🔗 [GNU AGPL v3 License](https://www.gnu.org/licenses/agpl-3.0.html).
