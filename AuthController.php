<?php

namespace Modules\Authentication\Presentation\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Modules\Authentication\Application\Actions\AuthUserAction;
use Modules\Authentication\Application\Actions\LoginUserAction;
use Modules\Authentication\Application\Actions\LogoutUserAction;
use Modules\Authentication\Application\Actions\RefreshTokenAction;
use Modules\Authentication\Application\Actions\RegisterUserAction;
use Modules\Authentication\Application\DTOs\Auth\Input\AuthUserInputDto;
use Modules\Authentication\Application\DTOs\Auth\Input\LoginInputDto;
use Modules\Authentication\Application\DTOs\Auth\Input\LogoutInputDto;
use Modules\Authentication\Application\DTOs\Auth\Input\RegisterInputDto;
use Modules\Authentication\Presentation\Http\Requests\LoginRequest;
use Modules\Authentication\Presentation\Http\Requests\LogoutRequest;
use Modules\Authentication\Presentation\Http\Requests\RefreshTokenRequest;
use Modules\Authentication\Presentation\Http\Requests\RegisterRequest;
use Modules\Authentication\Presentation\Http\Resources\AuthResource;
use Modules\Authentication\Presentation\Http\Resources\UserResource;
use Modules\Shared\Domain\ValueObjects\UserId;
use Modules\Shared\Presentation\Http\Controllers\BaseController;

class AuthController extends BaseController
{
    public function __construct(
        private readonly LoginUserAction $loginUserAction,
        private readonly LogoutUserAction $logoutUserAction,
        private readonly RegisterUserAction $registerUserAction,
        private readonly RefreshTokenAction $refreshTokenAction,
        private readonly AuthUserAction $authUserAction,
    ) {
    }

    public function login(LoginRequest $request)
    {
        return $this->handle(function () use ($request) {

            $output = $this->loginUserAction->execute(
                new LoginInputDto(
                    email: $request->input('email'),
                    password: $request->input('password')
                )
            );
            return [
                'message' => __('auth.login.success'),
                'data' => new AuthResource($output)
            ];
        });
    }

    public function register(RegisterRequest $request)
    {
        return $this->handle(function () use ($request) {

            $output = $this->registerUserAction->execute(
                new RegisterInputDto(
                    name: $request->input('name'),
                    email: $request->input('email'),
                    password: $request->input('password')
                )
            );

            return [
                'message' => __('auth.register.success').', '.__('email.verification.sent'),
                'data' => new AuthResource($output)
            ];
        });
    }

    public function refreshToken(RefreshTokenRequest $request)
    {
        return $this->handle(function () use ($request) {

            $access_token = $this->refreshTokenAction->execute($request->input('refresh_token'));

            return [
                'message' => '',
                'data' => [
                    'access_token' => $access_token->plainText()
                ]
            ];
        });
    }

    public function logout(LogoutRequest $request)
    {
        return $this->handle(function () use ($request) {

            $this->logoutUserAction->execute(
                new LogoutInputDTO(
                    userId: new UserId($request->user()->id)
                )
            );
            return [
                'message' => __('auth.logout.success'),
            ];
        });
    }

    public function me(Request $request): JsonResponse
    {
        return $this->handle(function () use ($request) {

            $output = $this->authUserAction->execute(
                new AuthUserInputDto(
                    userId: new UserId($request->user()->id)
                )
            );
            return [
                'message' => __('auth.authenticated'),
                'data' => new UserResource($output)
            ];
        });
    }
}
