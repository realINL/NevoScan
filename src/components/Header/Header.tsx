import './Header.css'
import '../../styles/Fonts.css'

function Header() {
    return ( 
        // <div className="header">
        <header className='header'>
            <div className='header-content'>

                <h1 className='h1-header'>NevoScan</h1>

                <div className='header-info'>
                    <p className='p-header'>О приложении</p>
                    <p className='p-header'>Статьи</p>
                    <p className='p-header'>Контакты</p>
                </div>

            </div>

        </header>
        // </div> 
    );
}

export default Header;