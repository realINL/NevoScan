import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import Load from './components/Load/Load.tsx'
import { BrowserRouter, Route, Routes } from 'react-router'
import Result from './components/Result/Result.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
    <Routes>
      {/* <App /> */}
      <Route path='/' element={<App/>} />
      <Route path='/load' element={<Load/>} />
      <Route path='/r' element={<Result/>} />
    </Routes>
    </BrowserRouter>
  </StrictMode>,
)
