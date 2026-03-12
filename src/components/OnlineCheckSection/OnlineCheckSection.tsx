import { useNavigate } from 'react-router';
import './OnlineCheckSection.css'


function OnlineCheckSection() {
    const navigate = useNavigate();

    return (  
        <div className='onlineCheckSection'>
            <h1 className='h1-1'>Или проверьте родинки онлайн на сайте</h1>
            <button 
            className='button'
            onClick={() => navigate("/load")}
            >Проверить</button>
        </div>
    );
}

export default OnlineCheckSection;