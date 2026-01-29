<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class HealthController extends Controller
{
    public function __invoke(Request $request)
    {
        $status = [
            'status' => 'ok',
            'timestamp' => now()->toIso8601String(),
            'services' => [
                'database' => 'unknown',
                'redis' => 'unknown',
            ]
        ];

        // Check Database
        try {
            DB::connection()->getPdo();
            $status['services']['database'] = 'ok';
        } catch (\Exception $e) {
            $status['status'] = 'error';
            $status['services']['database'] = 'error: ' . $e->getMessage();
        }

        // Check Redis
        try {
            Redis::connection()->ping();
            $status['services']['redis'] = 'ok';
        } catch (\Exception $e) {
            $status['status'] = 'error';
            $status['services']['redis'] = 'error: ' . $e->getMessage();
        }

        $httpStatus = $status['status'] === 'ok' ? 200 : 503;

        return response()->json($status, $httpStatus);
    }
}
