import type React from 'react';
import './LoadForm.css';

export type LoadFormProps = {
    /** После отправки анализа — блокируем форму до ответа сервера */
    isLoading?: boolean;
    dragActive: boolean;
    previewUrl: string | null;
    confirm: boolean;
    error: string | null;
    onDragEnter: (e: React.DragEvent<HTMLFormElement>) => void;
    onDragOver: (e: React.DragEvent<HTMLFormElement>) => void;
    onDragLeave: (e: React.DragEvent<HTMLFormElement>) => void;
    onDrop: (e: React.DragEvent<HTMLFormElement>) => void;
    onReset: React.FormEventHandler<HTMLFormElement>;
    onFileChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
    onConfirmChange: React.ChangeEventHandler<HTMLInputElement>;
    onAnalyze: () => void;
};

function LoadForm({
    isLoading = false,
    dragActive,
    previewUrl,
    confirm,
    error,
    onDragEnter,
    onDragOver,
    onDragLeave,
    onDrop,
    onReset,
    onFileChange,
    onConfirmChange,
    onAnalyze,
}: LoadFormProps) {
    const formId = 'load-upload-form';
    const disabledSubmit = !confirm || !previewUrl || isLoading;
    const disabledForm = isLoading;

    return (
        <div className={`load-form${disabledForm ? ' load-form--busy' : ''}`}>
            <h1 className="load-title">Онлайн исследование</h1>
            <h2 className="load-subtitle">Загрузите изображение вашей родинки<br />Убедитесь, что оно соответствует требованиям</h2>

            <h2 className="load-form-title">Добавьте изображение родинки</h2>

            <form
                id={formId}
                className={`load-file ${dragActive ? 'drag' : ''}`}
                onDragEnter={onDragEnter}
                onDragOver={onDragOver}
                onDragLeave={onDragLeave}
                onDrop={onDrop}
                onReset={onReset}
            >
                <label className="label label--dropzone" htmlFor="upload-photo-input">
                    <span className="load-file__sr-only">Выбрать фото родинки</span>
                </label>
                <input
                    id="upload-photo-input"
                    className="input input--dropzone"
                    type="file"
                    accept="image/jpeg,image/jpg,image/png"
                    multiple={false}
                    disabled={disabledForm}
                    onChange={onFileChange}
                />

                {!previewUrl && (
                    <>
                        <p className="load-file__text">Нажмите или перетащите сюда фото</p>
                        <p className="load-file__hint">JPG, PNG до 10 МБ</p>
                    </>
                )}

                {previewUrl && (
                    <>
                        <img className="file-preview" src={previewUrl} alt="Preview" />
                    </>
                )}
            </form>

            {!error ? (
                <button
                    className="button_reset"
                    type="reset"
                    form={formId}
                    disabled={!previewUrl || disabledForm}
                >
                    Удалить фото
                </button>
            ) : (
                <p className="load__error">{error}</p>
            )}

            <label className={`agreement${disabledForm ? ' agreement--disabled' : ''}`}>
                <input
                    type="checkbox"
                    name="agreement"
                    checked={confirm}
                    disabled={disabledForm}
                    onChange={onConfirmChange}
                    className="agreement__input"
                />
                <span className="agreement__checkmark" aria-hidden />
                <span className="agreement__label">
                    Принять{' '}
                    <a
                        href="/documents/agreementV0.pdf"
                        target="_blank"
                        rel="noreferrer"
                        tabIndex={disabledForm ? -1 : undefined}
                        aria-disabled={disabledForm || undefined}
                        onClick={disabledForm ? (e) => e.preventDefault() : undefined}
                    >
                        условия
                    </a>{' '}
                    обработки данных и политики конфиденциальности
                </span>
            </label>

            <button type="button" className="load__submit" disabled={disabledSubmit} onClick={onAnalyze}>
                Анализировать
            </button>
            {/* {error && <p className="load__error">{error}</p>} */}
        </div>
    );
}

export default LoadForm;
