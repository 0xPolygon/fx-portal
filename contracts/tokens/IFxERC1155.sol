// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0<0.7.0;

interface IFxERC1155 {
    function fxManager() external returns(address);
    function initialize(address fxManager_, address connectedToken_, string calldata uri_) external;
    function connectedToken() external returns(address);
    function mint(address user, uint256 id, uint256 amount, bytes calldata data) external;
    function mintBatch(address user, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function burn(address user, uint256 id, uint256 amount) external;
    function burnBatch(address user, uint256[] calldata ids, uint256[] calldata amounts) external;
}
