import { useState } from 'react';
import { ApiError, uploadImage, waitForTaskResult } from '../api/api';
import type { AnalysisResult, TaskStatusResponse } from '../types/types';

export class AnalyzeError extends Error {
    constructor(message: string,) {
        super(message);
        this.name = 'AnalyzeError';
    }
}
type AnalyzeErrorUi = undefined | null | string;

interface UseAnalyzeReturn {
    isLoading: boolean;
    error: string | null;
    analyzeErrorUi: AnalyzeErrorUi;
    analysis: AnalysisResult | null;
    runAnalyze: (file: File) => Promise<void>;
    resetAnalyze: () => void;
    setAnalyzeError: (message: string | null) => void;
}

const LOADING_DURATION_MS = 1000;
const delay = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

const toAnalysisResult = (payload: TaskStatusResponse): AnalysisResult => {
    const payloadObject = payload as unknown as Record<string, unknown>;
    const rawResult = payload.result && typeof payload.result === 'object'
        ? (payload.result as unknown as Record<string, unknown>)
        : payloadObject;

    return {
        status:
            typeof rawResult.status === 'string' ? rawResult.status : 'failed',
        probability_malign:
            typeof rawResult.probability_malign === 'number' ? rawResult.probability_malign : 0,
        probability_benign:
            typeof rawResult.probability_benign === 'number' ? rawResult.probability_benign : 0,
        result: typeof rawResult.result === 'string' ? rawResult.result : '',
        cropped_image_url:
            typeof rawResult.cropped_image_url === 'string' ? rawResult.cropped_image_url : '',
        hair_removed_rgb_image_url:
            typeof rawResult.hair_removed_rgb_image_url === 'string' ? rawResult.hair_removed_rgb_image_url : '',
        mask_url: typeof rawResult.mask_url === 'string' ? rawResult.mask_url : '',
    };
};

export function useAnalyze(): UseAnalyzeReturn {
    const [isLoading, setIsLoading] = useState(false);
    const [formError, setFormError] = useState<string | null>(null);
    const [analyzeErrorUi, setAnalyzeErrorUi] = useState<AnalyzeErrorUi>(undefined);
    const [analysis, setAnalysis] = useState<AnalysisResult | null>(null);

    const runAnalyze = async (file: File) => {
        setAnalyzeErrorUi(undefined);
        setAnalysis(null);
        setIsLoading(true);

        const startedAt = Date.now();

        try {
            let payload = await uploadImage(file);

            if (payload.status === 'pending') {
                const taskId = typeof payload.task_id === 'string' ? payload.task_id : null;
                if (!taskId) {
                    throw new AnalyzeError('Сервер вернул pending без task_id');
                }
                payload = await waitForTaskResult(taskId);
            } else if (payload.result?.status === 'no_object') {
                console.log('No object!')
                throw new AnalyzeError('На фото не обнаружена родинка. Загрузите другое изображение.');
            } else if (payload.status === 'failed' || payload.status === 'error') {
                throw new AnalyzeError('Анализ завершился с ошибкой');
            }

            setAnalysis(toAnalysisResult(payload));
        } catch (e) {
             if (e instanceof ApiError && e.status === 400) {
                setAnalyzeErrorUi('Сервер не принял тип файла. Загрузите JPG, JPEG или PNG.');
            } else if (e instanceof AnalyzeError) {
                console.log('SET UIError ‘{e.message}‘')
                setAnalyzeErrorUi(e.message);
            } else {
                setAnalyzeErrorUi(null);
            }
            throw e;
        } finally {
            const elapsed = Date.now() - startedAt;
            if (elapsed < LOADING_DURATION_MS) {
                await delay(LOADING_DURATION_MS - elapsed);
            }
            setIsLoading(false);
        }
    };

    const resetAnalyze = () => {
        setIsLoading(false);
        setFormError(null);
        setAnalyzeErrorUi(undefined);
        setAnalysis(null);
    };

    const setAnalyzeError = (message: string | null) => {
        setFormError(message);
    };

    return {
        isLoading,
        error: formError,
        analyzeErrorUi,
        analysis,
        runAnalyze,
        resetAnalyze,
        setAnalyzeError,
    };
}
