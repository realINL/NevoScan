import './Header.css'
import '../../styles/Fonts.css'
import { useNavigate } from 'react-router';
import Contacts from '../About/Contacts';
function Header() {
    const navigate = useNavigate();

    return ( 
        <header className='header'>
            <div className='header-content'>

                <h1 className='h1-header' onClick={() => navigate("/")}>NevoScan</h1>

                <div className='header-info'>
                    <p className='p-header' onClick={() => navigate("/about")}>О приложении</p>
                    <p className='p-header'>Статьи</p>
                    <Contacts />
                </div>

            </div>

        </header>
        // </div> 
    );
}

export default Header;