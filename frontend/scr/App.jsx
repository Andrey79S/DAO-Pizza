import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';

const TOKEN_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function decimals() view returns (uint8)"
];

function App(){
  const [provider, setProvider] = useState(null);
  const [address, setAddress] = useState(null);
  const [balance, setBalance] = useState('0');
  const [tokenAddress, setTokenAddress] = useState('');

  useEffect(()=>{
    if(window.ethereum) setProvider(new ethers.providers.Web3Provider(window.ethereum));
  },[]);

  async function connect(){
    if(!provider) return alert('Install MetaMask');
    await provider.send("eth_requestAccounts", []);
    const signer = provider.getSigner();
    const addr = await signer.getAddress();
    setAddress(addr);
  }

  async function loadBalance(){
    if(!tokenAddress || !address) return;
    const token = new ethers.Contract(tokenAddress, TOKEN_ABI, provider);
    const bal = await token.balanceOf(address);
    const dec = await token.decimals();
    setBalance(ethers.utils.formatUnits(bal, dec));
  }

  return (
    <div style={{padding:20}}>
      <h1>DAO Pizza — Demo frontend</h1>
      <button onClick={connect}>Connect wallet</button>
      <div style={{marginTop:10}}>Address: {address}</div>

      <hr/>
      <div>
        <label>Token address: </label>
        <input value={tokenAddress} onChange={(e)=>setTokenAddress(e.target.value)} style={{width: '60%'}} />
        <button onClick={loadBalance}>Load balance</button>
      </div>
      <div>Token balance: {balance}</div>
    </div>
  )
}

export default App;
