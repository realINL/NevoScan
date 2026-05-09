import { Link } from 'react-router';
import Header from '../Header/Header';
import '../../styles/Fonts.css';
import './About.css';

function About() {
    return (
        <div className="about-page">
            <Header />
            <main className="about">
                <h1 className="about__title">О приложении</h1>
                <div className="about__body">
                    <p className="about__text">
                        NevoScan — это приложение для проверки родинки на наличие рака. Оно позволяет
                        пользователям загружать изображения родинки и получать результаты анализа.
                    </p>
                    <p className="about__text">
                        Приложение использует алгоритмы машинного обучения для анализа изображений
                        родинки и определения вероятности рака.
                    </p>
                    <p className="about__text">
                        Приложение разработано командой NevoScan и является бесплатным. Приложение
                        доступно для iOS и Android.
                    </p>
                    <p className="about__note">
                        Результат онлайн‑проверки не является медицинским диагнозом.
                    </p>
                </div>
                <div className="buttons">
                    <Link className="about__cta" to="/analyze">
                        Онлайн‑проверка
                    </Link>

                    <a className="rools" href="/documents/agreementV0.pdf" target="_blank" rel="noreferrer">Правила использования</a>
                </div>
            </main>
        </div>
    );
}

export default About;
