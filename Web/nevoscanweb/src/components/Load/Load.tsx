import './Load.css';
import { useState } from 'react';
import type React from 'react';
import Result from '../Result/Result';
import Instruction from '../Instruction/Instruction';
import LoadForm from './LoadForm';
import Header from '../Header/Header';
import { useAnalyze } from '../../hooks/useAnalyze';

function Load() {
    const ACCEPTED_MIME_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/heic'];
    const [confirm, setConfirm] = useState(false);
    const [file, setFile] = useState<File | null>(null);  // загруженный файл
    const [previewUrl, setPreviewUrl] = useState<string | null>(null); // загруженный файл просмотр
    const [dragActive, setDragActive] = useState(false); // drag&drop
    const [showResult, setShowResult] = useState(false) // показать результат анализа
    const { isLoading, error, analyzeErrorUi, analysis, runAnalyze, resetAnalyze, setAnalyzeError } =
        useAnalyze();

    const isSupportedImageType = (candidate: File): boolean => ACCEPTED_MIME_TYPES.includes(candidate.type);

    const applySelectedFile = (selectedFile: File) => {
        if (!isSupportedImageType(selectedFile)) {
            setFile(null);
            setPreviewUrl(null);
            setAnalyzeError('Поддерживаются только файлы JPG, JPEG и PNG.');
            return;
        }

        setAnalyzeError(null);
        setFile(selectedFile);
        const url = URL.createObjectURL(selectedFile);
        setPreviewUrl(url);
    };

    // Обработка загрузки файли в форму
    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        e.preventDefault();

        if (e.target.files && e.target.files[0]) {
            applySelectedFile(e.target.files[0]);
        }
    }

    // Обработка drag&drop

    const handleDrag = (e: React.DragEvent<HTMLFormElement>) => {
        e.preventDefault();
        if (isLoading) return;
        setDragActive(true);
    };

    const handleLeave = (e: React.DragEvent<HTMLFormElement>) => {
        e.preventDefault();
        if (isLoading) return;
        setDragActive(false);
    };

    const handleDrop = (e: React.DragEvent<HTMLFormElement>) => {
        e.preventDefault();
        setDragActive(false);
        if (isLoading) return;

        if (e.dataTransfer.files && e.dataTransfer.files[0]) {
            applySelectedFile(e.dataTransfer.files[0]);
        }
    };

    // Reset

    const resetAnalysis = () => {
        setFile(null);
        setPreviewUrl(null);
        setShowResult(false);
        resetAnalyze();
    };

    const handleFormReset: React.FormEventHandler<HTMLFormElement> = () => {
        resetAnalysis();
    };

    const handleConfirmationChange: React.ChangeEventHandler<HTMLInputElement> = () => {
        setConfirm((c) => !c);
    };

    // Отображение результата 



    const handleAnalyze = async () => {
        if (!file) return;

        try {
            await runAnalyze(file);
        } catch {
            // ошибка уже в error из useAnalyze; показываем экран результата с ErrorView
        }
        setShowResult(true);
    }


    return (
        <div className="load-page">
        <Header/>
       
        <div className="load">
            {showResult ? (
                previewUrl && (analysis || analyzeErrorUi !== undefined) ? (
                    <Result
                        image={previewUrl}
                        maligancy={analysis?.probability_malign ?? 0}
                        benign={analysis?.probability_benign ?? 0}
                        result={analysis?.result ?? ''}
                        croppedImageUrl={analysis?.cropped_image_url}
                        hairRemovedImageUrl={analysis?.hair_removed_rgb_image_url}
                        maskImageUrl={analysis?.mask_url}
                        onNewAnalysis={resetAnalysis}
                        error={analyzeErrorUi}
                    />
                ) : null
            ) : (
                <div className="load__columns">
                        <LoadForm
                            isLoading={isLoading}
                            dragActive={dragActive}
                            previewUrl={previewUrl}
                            confirm={confirm}
                            error={error}
                            onDragEnter={handleDrag}
                            onDragOver={handleDrag}
                            onDragLeave={handleLeave}
                            onDrop={handleDrop}
                            onReset={handleFormReset}
                            onFileChange={handleFileChange}
                            onConfirmChange={handleConfirmationChange}
                            onAnalyze={handleAnalyze}
                        />
                        {isLoading ? (
                            <div className="load__loading load__aside" aria-busy="true">
                                <div className="loader" aria-hidden />
                                <p className="load__loading-text">Анализ изображения...</p>
                            </div>
                        ) : (
                            <Instruction />
                        )}
                </div>
            )}

        </div>
        </div>
    );
}

export default Load;
