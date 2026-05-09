import './Contacts.css';

function Contacts() {
    return (
        <details className="contacts">
            <summary className="contacts__trigger">Контакты</summary>
            <div className="contacts__panel">
                <a className="contacts__link" href="mailto:realinl@ya.ru">
                    realinl@ya.ru
                </a>
            </div>
        </details>
    );
}

export default Contacts;
