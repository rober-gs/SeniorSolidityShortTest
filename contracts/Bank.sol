//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IBank.sol";
import "hardhat/console.sol";

contract Bank  is IBank {

    uint private numberOfBlocks = 100;
    uint private percentage = 3;
    mapping (address=>Account) private accounts;

    constructor() payable {}
    receive() external payable {}

    function deposit(uint256 amount) external payable override returns (bool)
    {
        require( !isContract(msg.sender), "Only EOA Accounts");
        require( msg.value > 0, "Amount Higher Than 0");
        require( msg.value == amount, "On ETH solely");

        (bool success, )  = address(this).call{value: amount}("");
        require( success, "Failed to send Ether");
        accounts[msg.sender].deposit += amount;
        accounts[msg.sender].lastInterestBlock += block.number;


        emit Deposit(msg.sender, amount);

        return true;
    }
    function withdraw(uint256 amount) external override returns (uint256)
    {

        Account memory user =  accounts[msg.sender];

        require(user.deposit > 0, "no balance");
        
        uint fee = calculateFee(user.deposit, user.lastInterestBlock);
        
        uint total = user.deposit + fee;
        
        require(amount <= total, "amount exceeds balance");

        (bool success, )  = msg.sender.call{value: total}("");
        require( success, "Failed to send Ether");

        emit Withdraw(msg.sender, total);

        return total;
    }

    function calculateFee(uint256 balance, uint256 lastInterestBlock) internal view returns(uint256)
    {
        uint totalBlocks = block.number - lastInterestBlock;
        console.log("totalBlocks", totalBlocks);

        if(totalBlocks <= 0 ) return 0;

        uint pctProportional = (totalBlocks * percentage) / numberOfBlocks;

        return (balance * pctProportional)/100;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function getBalance() external view override returns (uint256)
    {
        return accounts[msg.sender].deposit;
    }
}



/*
    Functional Requirements
*/

// ✅ 1. La cuenta de un cliente bancario está representada por la dirección de su monedero.
// ✅ 2. Un cliente del banco debe ser capaz de depositar una cantidad superior a 0 de tokens en su propia cuenta. Los depósitos pueden realizarse en ETH únicamente a efectos de este reto.
// 3. Un cliente del banco debe poder retirar sólo hasta la cantidad depositada en su propia cuenta más los intereses acumulados.
// 4. La tasa de interés de los depósitos es del 3% por cada 100 bloques. Si un usuario retira su depósito antes o después de los 100 bloques, recibirá una cantidad de intereses proporcional.
// 5. Un cliente de un banco debe poder depositar tantas veces como desee en la misma cuenta, y si es así, los intereses deben ser *contabilizados* cada vez que el depósito y la retirada sean llamados por el usuario.
// 6. El contrato inteligente debe tener suficiente ETH para subvencionar los intereses acumulados por el usuario (**Nota**: Aquí es donde esta prueba se acorta, eliminamos las funcionalidades de colateral, préstamo y reembolso de préstamos).
// 7. Cada función de cambio de estado definida en la interfaz `IBank`, debe emitir el evento correspondiente definido en la parte superior de dicha interfaz con los parámetros correctos especificados en los comentarios del código para cada evento.
