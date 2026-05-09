import type { TaskStatusResponse } from '../types/types';

export class ApiError extends Error {
    status: number;
    details: string;

    constructor(message: string, status: number, details = '') {
        super(message);
        this.name = 'ApiError';
        this.status = status;
        this.details = details;
    }
}

// const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '';
const API_BASE_URL = "/api";

const buildUrl = (path: string): string => {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    const normalizedPath = path.startsWith('/') ? path : `/${path}`;
    return `${API_BASE_URL}${normalizedPath}`;
};

const toErrorDetails = async (response: Response): Promise<string> => {
    try {
        const text = await response.text();
        return text.slice(0, 1000);
    } catch {
        return '';
    }
};

export async function requestJson<T>(
    path: string,
    init?: RequestInit,
): Promise<T> {
    const response = await fetch(buildUrl(path), init);

    if (!response.ok) {
        const details = await toErrorDetails(response);
        throw new ApiError(`API request failed: ${response.status}`, response.status, details);
    }

    return response.json() as Promise<T>;
}

export async function getJson<T>(
    path: string,
    init?: Omit<RequestInit, 'method'>,
): Promise<T> {
    return requestJson<T>(path, { ...init, method: 'GET' });
}

export async function postFormJson<T>(
    path: string,
    formData: FormData,
    init?: Omit<RequestInit, 'method' | 'body' | 'headers'>,
): Promise<T> {
    return requestJson<T>(path, {
        ...init,
        method: 'POST',
        body: formData,
    });
}

export async function uploadImage(file: File): Promise<TaskStatusResponse> {
    const formData = new FormData();
    formData.append('file', file);
    return postFormJson<TaskStatusResponse>('load_image', formData);
}

export async function getTaskStatus(taskId: string): Promise<TaskStatusResponse> {
    return getJson<TaskStatusResponse>(`task/${taskId}`);
}

export async function getImageUrl(presigned_url: string): Promise<string> {
    try {
        const response = await fetch(presigned_url);
        if (!response.ok) {
            throw new Error('Не удалось получить изображение по presigned_url');
        }
        const blob = await response.blob();
        return URL.createObjectURL(blob);
    } catch (e) {
        return '';
    }
}

const delay = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

export async function waitForTaskResult(
    taskId: string,
    pollIntervalMs = 1500,
    maxPollAttempts = 40,
): Promise<TaskStatusResponse> {
    for (let attempt = 0; attempt < maxPollAttempts; attempt += 1) {
        await delay(pollIntervalMs);
        const payload = await getTaskStatus(taskId);

        if (payload.status === 'pending') {
            continue;
        }

        if (payload.result?.status=== 'no_object') {
            throw new Error('На фото не обнаружена родинка. Загрузите другое изображение.');
        }

        if (payload.status === 'failed' || payload.status === 'error') {
            throw new Error('Анализ завершился с ошибкой');
        }

        return payload;
    }

    throw new Error('Превышено время ожидания результата анализа');
}
