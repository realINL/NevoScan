export interface AnalysisResult {
    status: string;    
    probability_malign: number;
    probability_benign: number;
    result: string;
    cropped_image_url: string;
    hair_removed_rgb_image_url: string;
    mask_url: string;
}

export interface TaskStatusResponse {
    task_id: string;
    status: 'pending' | 'completed' | 'no_object' | 'failed' | 'error';
    created_at?: string;
    updated_at?: string;
    object_key?: string;
    result?: AnalysisResult;
}

export interface ResultProps {
    image: string;
    maligancy: number;
    benign: number;
    result: string;
    croppedImageUrl?: string;
    hairRemovedImageUrl?: string;
    maskImageUrl?: string;
    onNewAnalysis?: () => void;
    error?: string | null;
}
