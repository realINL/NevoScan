// import { useState } from 'react'
// import reactLogo from './assets/react.svg'
// import viteLogo from '/vite.svg'
import './App.css'
import Top from './components/Top'
import Header from './components/Header/Header'
// import OnlineCheckSection from './components/OnlineCheckSection/OnlineCheckSection'
// import Load from './components/Load/Load'

function App() {
  // const [count, setCount] = useState(0)

  return (
    <div className="app">
      {/* <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>
          Edit <code>src/App.tsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p> */}
      <Header />
      <div className="content">
        <Top />
        {/* <OnlineCheckSection/> */}
        {/* <Load/> */}
      </div>
    </div>
  )
}

export default App
