import './Result.css'

interface ResultProps {
    image: string
    score: number
}

function getDescription(score: number): string {
    if (score < 0.3) return 'Анализ не выявил никаких отклонений. Здоровая родинка'
    if (score < 0.7) return 'Стоит показать врачу'
    return 'Срочно обратитесь к врачу'
}

function Result({ image, score }: ResultProps) {
    const percent = Math.round(score * 100)
    const description = getDescription(score)

    return (
        <div className="result">
            <img className="result__image" src={image} alt="Загруженное фото" />
            <p className="result__percent">{percent}%</p>
            <p className="result__description">{description}</p>
            <p className="result__disclaimer">Не является диагнозом</p>
        </div>
    )
}

export default Result
