// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2<0.7.0;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    bytes4 INTERFACE_ID = 0x01ffc9a7;
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == INTERFACE_ID;
    }
}
