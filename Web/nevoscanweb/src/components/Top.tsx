import './Top.css'
import img from '../assets/image2.jpg'
import OnlineCheckSection from './OnlineCheckSection/OnlineCheckSection';

function Top() {
    return (  
        <div className='top'>
            <div className='buttns'>
                <div className="top-text">
                    <h1 className='h1-top'>Проверь родинки с приложением NevoScan</h1>
                    <p className='p-top'>Скачайте приложение и проверьте себя и своих близких на опасные родинки</p>
                    <button className='download-button'>Скачать приложение</button>
                </div>
                <OnlineCheckSection/>
            </div>

            <img className='img' src={img}/>
        </div>
    );
}

export default Top;