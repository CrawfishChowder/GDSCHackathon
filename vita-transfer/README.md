# Apply the Vita POC transfer

This bundle contains the uncommitted Vita controller work from the remote workspace. It does not include the unrelated root `assets/` folder and does not modify Git history.

1. In WSL, extract the GitHub ZIP and open a terminal at the extracted repository root (the folder containing `red-alert/` and `tools/`).
2. Extract this bundle into that repository root so `vita-controller/` and the Vita bridge/test files overlay into place:

   ```sh
   tar -xzf ~/Downloads/vita-poc-transfer.tar.gz -C .
   ```

3. Apply the game integration patch against the GitHub `main` snapshot:

   ```sh
   patch -p1 < vita-integration.patch
   ```

4. Confirm `vita-controller/CMakeLists.txt` and `red-alert/scripts/systems/vita_bridge.gd` exist. Then install/configure VitaSDK and follow `vita-controller/README.md` to build the VPK.

The patch updates only the project InputMap, controller look handling, and the README AI/source-reference disclosure. Review it before applying if the downloaded ZIP is not from the same current `main` revision.
