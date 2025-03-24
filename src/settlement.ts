import { ethers } from 'ethers';
import { JsonRpcProvider } from 'ethers'
import fs from "fs";

// Set up provider, signer, and contract
const provider = new ethers.JsonRpcProvider('http://127.0.0.1:8547');

async function setup() {
    const signer = await provider.getSigner();
    const settlementAddress = '0x54059294b42a9D438C84B8844916d403e982dcF6';
    const mailboxAddress = '0x1Db8fD89970B6FcBbbC50658b8DA2C272DfDcB57';

    // ABI of IntentSettlement contract
    const intentSettlementABI = JSON.parse(fs.readFileSync("contract/IntentSettlement", "utf-8")).abi;

    const intentSettlementContract = new ethers.Contract(settlementAddress, intentSettlementABI, signer);
    return { intentSettlementContract, mailboxAddress };
}

// Handle incoming intent
async function handleIncomingIntent(message: string) {
    try {
        const { intentSettlementContract, mailboxAddress } = await setup();
        const messageBytes = ethers.toUtf8Bytes(message);
        const tx = await intentSettlementContract.handle(1614990, mailboxAddress, messageBytes);
        console.log('Handle transaction sent:', tx);
        await tx.wait();
        console.log('Intent handled successfully');
    } catch (error) {
        console.error('Error handling intent:', error);
    }
}

// Fulfill intent if conditions are met
async function fulfillIntent(intentId: string, solverAddress: string) {
    try {
        const { intentSettlementContract } = await setup();
        const tx = await intentSettlementContract.fulfillIntent(intentId, solverAddress);
        console.log('Fulfill intent transaction sent:', tx);
        await tx.wait();
        console.log('Intent fulfilled successfully');
    } catch (error) {
        console.error('Error fulfilling intent:', error);
    }
}
