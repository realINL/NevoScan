import './Result.css'
import type { ResultProps } from '../../types/types';
import ErrorView from './ErrorView';

function Result({
    image,
    maligancy,
    benign,
    // result,
    croppedImageUrl,
    hairRemovedImageUrl,
    maskImageUrl,
    onNewAnalysis,
    error
}: ResultProps) {

    maligancy = Math.round(maligancy * 100)
    benign = Math.round(benign * 100)
    // const riskLevel = maligancy >= 70 ? 'Высокий риск' : maligancy >= 40 ? 'Средний риск' : 'Низкий риск'

    return (
        <div className="result">
            <div className="result__left">
                <h2 className="result__title">Результаты анализа</h2>
                <img className="result__image" src={image} alt="Загруженное фото" />
                {error !== undefined ? (
                    <ErrorView message={error ?? undefined} />
                ) : (
                    <>
                        {/* <div className="result__metrics"> */}
                        {/* <div className="result__metric result__metric--danger"> */}
                    <p className="result__subtitle">{benign}% безопасности</p>
                        <p className="result__metric-label">{benign}% доброкачественное новообразование</p>
                        <p className="result__metric-label">{maligancy}% злокачественное новообразование</p>
                        {/* <p className="result__metric-value">{maligancy}%</p> */}
                        {/* </div> */}
                        {/* <div className="result__metric result__metric--safe"> */}
                        {/* </div> */}
                        {/* </div> */}
                        <p className="result__disclaimer">Не является диагнозом</p>
                    </>
                )}
                {onNewAnalysis && (
                    <button type="button" className="result__new-analysis" onClick={onNewAnalysis}>
                        Новый анализ
                    </button>
                )}
           
               
               

                {/* <div className="result__summary">
                    <p className="result__result">Результат: {result} новообразование</p>
                    <p className="result__risk">{riskLevel}</p>
                </div> */}
            </div>

            {(croppedImageUrl || maskImageUrl) && (
                <div className="result__extra">
                    <p className="result__section-title">Процесс анализа:</p>
                    <div className="result__extra-images">
                        {croppedImageUrl && (
                            <figure className="result__figure">
                                <img className="result__thumb" src={croppedImageUrl} alt="Обрезанная область новообразования" />
                                <figcaption className="result__caption">1. Обрезка</figcaption>
                            </figure>
                        )}
                        {hairRemovedImageUrl && (
                            <figure className="result__figure">
                                <img className="result__thumb" src={hairRemovedImageUrl} alt="Маска сегментации" />
                                <figcaption className="result__caption">2. Удаление волос</figcaption>
                            </figure>
                        )}
                        {maskImageUrl && (
                            <figure className="result__figure">
                                <img className="result__thumb" src={maskImageUrl} alt="Маска сегментации" />
                                <figcaption className="result__caption">3. Маска</figcaption>
                            </figure>
                        )}
                    </div>

                    <div className="result__extra-description">
                        <h2 className="result__extra-description-title">Об анализе</h2>
                        <p className="result__extra-description-text">Анализ выполнене нейросетевой моделью</p>
                        <p className="result__extra-description-text">Изображение проходит через несколько этапов обработки:</p>
                        <span className="result__extra-description-text">
                            - обрезка области новообразования<br />
                            - маска сегментации<br />
                            - нейросетевая модель определяет вероятности <br/>
                        </span>
                    </div>
                </div>
            )}
  
           
        </div>
    )
}

export default Result
