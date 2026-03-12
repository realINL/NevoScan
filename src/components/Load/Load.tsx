import './Load.css'
import { useState } from 'react';
import type React from 'react';
import Result from '../Result/Result';
import Instruction from '../Instruction/Instruction';
import Header from '../Header/Header';

function Load() {
    const [confirm, setConfirm] = useState(false);
    const [file, setFile] = useState<File | null>(null);  // загруженный файл
    const [previewUrl, setPreviewUrl] = useState<string | null>(null); // загруженный файл просмотр
    const [dragActive, setDragActive] = useState(false); // drag&drop
    const [showResult, setShowResult] = useState(false) // показать результат анализа
    const [isLoading, setIsLoading] = useState(false)
    const [score, setScore] = useState<number | null>(null)
    const [error, setError] = useState<string | null>(null)

    // Обработка загрузки файли в форму
    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        e.preventDefault();

        if (e.target.files && e.target.files[0]) {
            setFile(e.target.files[0]);  
            const url = URL.createObjectURL(e.target.files[0]);
            setPreviewUrl(url);
        }
    }

    // Обработка drag&drop

    const handleDrag = (e: React.DragEvent<HTMLFormElement>) => {
        e.preventDefault()
        setDragActive(true)
    }

     const handleLeave = (e: React.DragEvent<HTMLFormElement>) => {
        e.preventDefault()
        setDragActive(false)

    }

    const handleDrop = (e: React.DragEvent<HTMLFormElement>) => {
        e.preventDefault()
        setDragActive(false)

        if (e.dataTransfer.files && e.dataTransfer.files[0]) {
            setFile(e.dataTransfer.files[0]);
            const url = URL.createObjectURL(e.dataTransfer.files[0]);
            setPreviewUrl(url);
        }

    }

    // Reset

    const handleReset = () => {
        setFile(null);
        setPreviewUrl(null);
        setShowResult(false);
        setIsLoading(false);
        setScore(null);
        setError(null);
    }

    const handleConfirmationChange = () => {
        setConfirm(!confirm);
    }

    // Отображение результата 



    const handleShowResult = () => {
        setShowResult(true);
    }

    const LOADING_DURATION_MS = 5000;

    const delay = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

    const extractScore = (payload: unknown): number => {
        // ожидаем score в диапазоне 0..1; если приходит 0..100 — нормализуем
        const normalize = (n: number) => {
            if (!Number.isFinite(n)) return 0;
            if (n > 1) return Math.max(0, Math.min(1, n / 100));
            return Math.max(0, Math.min(1, n));
        };

        if (typeof payload === 'number') return normalize(payload);

        if (Array.isArray(payload)) {
            const first = payload[0];
            if (typeof first === 'number') return normalize(first);
            if (typeof first === 'string') {
                const maybeNumber = Number(first.split(':').at(-1));
                if (Number.isFinite(maybeNumber)) return normalize(maybeNumber);
            }
        }

        if (payload && typeof payload === 'object') {
            const obj = payload as Record<string, unknown>;
            const candidates = [obj.score, obj.probability, obj.risk, obj.confidence];
            for (const c of candidates) {
                if (typeof c === 'number') return normalize(c);
                if (typeof c === 'string') {
                    const n = Number(c);
                    if (Number.isFinite(n)) return normalize(n);
                }
            }
        }

        return 0;
    };

    const handleAnalyze = async () => {
        if (!file) return;

        setError(null);
        setIsLoading(true);

        const startedAt = Date.now();

        try {
            const formData = new FormData();
            formData.append('image', file); // 'image' - должно совпадать с параметром в FastAPI

            const res = await fetch("http://127.0.0.1:8000/analyze", {
                method: "POST",
                body: formData,
            });

            if (!res.ok) {
                throw new Error(`Ошибка сервера: ${res.status}`);
            }

            const payload = await res.json();
            const nextScore = extractScore(payload);
            setScore(nextScore);
        } catch (e) {
            setError(e instanceof Error ? e.message : 'Не удалось выполнить анализ');
            return;
        } finally {
            const elapsed = Date.now() - startedAt;
            if (elapsed < LOADING_DURATION_MS) {
                await delay(LOADING_DURATION_MS - elapsed);
            }
            setIsLoading(false);
        }

        handleShowResult();
    }


    

    return (
        <>
        <Header/>
       
        <div className="load">
            {showResult ? (
                previewUrl && score !== null ? <Result image={previewUrl} score={score} /> : null
            ) : isLoading ? (
                <div className="load__loading">
                    <div className="load__spinner" aria-hidden />
                    <p className="load__loading-text">Анализ изображения...</p>
                </div>
            ) : (
            <>
            <h1 className="load__title">Онлайн исследование</h1>
            <Instruction/>
            <p className="load__subtitle">Загрузите фото родинки для предварительной оценки</p>

            {/* <div className="examples">
                <div className="example-card">
                    <img className="example-card__img" src={ex2} alt="Пример 1" />
                </div>
                <div className="example-card">
                    <img className="example-card__img" src={ex1} alt="Пример 2" />
                </div>
                <div className="example-card">
                    <img className="example-card__img" src={ex3} alt="Пример 3" />
                </div>
            </div> */}

            {/* <div className="load-file"> */}
                {/* <div className="load-file__icon" aria-hidden>
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                        <polyline points="17 8 12 3 7 8" />
                        <line x1="12" y1="3" x2="12" y2="15" />
                    </svg>
                </div>
                <p className="load-file__text">Нажмите или перетащите сюда фото</p>
                <p className="load-file__hint">JPG, PNG до 10 МБ</p> */}

                <form className={`load-file ${dragActive ? "drag" : ""}`}
                onDragEnter={handleDrag}
                onDragOver={handleDrag}
                onDragLeave={handleLeave}
                onDrop={handleDrop}
                onReset={handleReset}
                >
                    {!previewUrl && 
                    <>
                    <p className="load-file__text">Нажмите или перетащите сюда фото</p>
                    <p className="load-file__hint">JPG, PNG до 10 МБ</p> 
                    </>}
                    
                    <label className='label'>
                        <input
                        className='input' 
                        type='file'
                        multiple={false}
                        onChange={handleFileChange}
                        />
                    </label>
                    {previewUrl && (
                        <>
                        <img className="file-preview" src={previewUrl} alt="Preview" />
                         <button className="button_reset" type='reset'>Сбросить</button>
                        </>
                        )}
                   

                </form>

            {/* </div> */}

            <label className="agreement">
                <input
                    type="checkbox"
                    name="agreement"
                    checked={confirm}
                    onChange={handleConfirmationChange}
                    className="agreement__input"
                />
                <span className="agreement__checkmark" aria-hidden />
                <span className="agreement__label">Принять <a href='/documents/agreementV0.pdf' target='_blank'>условия</a> обработки данных и политики конфиденциальности</span>
            </label>

            <button type="button" className="load__submit" disabled={!confirm} onClick={handleAnalyze}>
                Анализировать
            </button>
            {error && <p className="load__error">{error}</p>}
            </>
            )}

        </div>
         </>
    );
}

export default Load;
